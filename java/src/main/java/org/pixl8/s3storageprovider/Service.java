package org.pixl8.s3storageprovider;

import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.auth.credentials.*;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.paginators.*;
import software.amazon.awssdk.core.sync.RequestBody;
import java.nio.file.Paths;
import lucee.runtime.type.Query;
import lucee.runtime.type.Struct;
import lucee.loader.engine.CFMLEngineFactory;
import lucee.runtime.exp.PageException;
import java.util.Date;
import java.util.List;
import java.io.File;

/**
 * This is a private service for our Lucee CFML Preside Storage
 * Provider. It is a focused API with simple values for our
 * CFML logic to call when meeting the interface requirements
 * for Preside. It is using AWS official java sdk v2 to ensure
 * best possible performance at this time.
 *
 */
public class Service {

	private S3Client _s3Client;
	private String   _bucket;
	private String   _region;

	/**
	 * Our simple service constructor takes region, bucket, accesskey and secret key.
	 * All operations using an instance of this service are then operating within those
	 * boundaries.
	 *
	 */
	public Service( String region, String bucket, String accessKey, String secretKey ) {
		_bucket   = bucket;
		_region   = region;
		_s3Client = S3Client.builder()
		                    .region( Region.of( _region ) )
		                    .credentialsProvider( StaticCredentialsProvider.create( AwsBasicCredentials.create( accessKey, secretKey ) ) )
		                    .build();
	}


	/**
	 * Returns true if there are no errors making an API call to get the configured
	 * bucket
	 */
	public boolean checkS3Access() {
		try {
			_s3Client.listBuckets();
		} catch( Exception e ) {
			return false;
		}

		return true;
	}

	/**
	 * Returns true if there are no errors making an head API call to the bucket
	 */
	public boolean checkBucketAccess() {
		try {
			_s3Client.headBucket( HeadBucketRequest.builder().bucket( _bucket ).build() );
		} catch( Exception e ) {
			return false;
		}

		return true;
	}

	/**
	 * Returns true if there are no errors making an API call to get the configured
	 * bucket and that the bucket
	 */
	public boolean checkBucketRegion() {
		GetBucketLocationResponse resp = _s3Client.getBucketLocation( GetBucketLocationRequest.builder().bucket( _bucket ).build() );
		return resp.locationConstraintAsString().equals( _region );
	}

	/**
	 * Returns a cfquery result of objects matching the provided
	 * prefix. This ensures no conversion necessary from CFML code
	 * after calling this java method.
	 *
	 */
	public Query listObjects( String prefix ) throws PageException {
		ListObjectsV2Request  req            = ListObjectsV2Request.builder().prefix( prefix ).bucket( _bucket ).build();
		ListObjectsV2Iterable iterableResult = _s3Client.listObjectsV2Paginator( req );

		Query q    = CFMLEngineFactory.getInstance().getCreationUtil().createQuery( new String[] { "name", "path", "size", "lastmodified" }, new String[] { "VARCHAR", "VARCHAR", "DOUBLE", "DATE" }, 0, "query" );
		int   rows = 0;

		for ( ListObjectsV2Response responses : iterableResult ) {
			List<S3Object> objs = responses.contents();
			for ( S3Object s3Obj : objs ) {
				File f = new File( s3Obj.key() ); // not a real file, using to get directory and filename
				File p = f.getParentFile();

				rows++;
				q.addRow(1);
				q.setAt( "name"        , rows, f.getName() );
				q.setAt( "size"        , rows, Double.valueOf( s3Obj.size() ) );
				q.setAt( "lastmodified", rows, Date.from( s3Obj.lastModified() ) );

				if ( p != null ) {
					q.setAt( "path", rows, "/" + p.toString() );
				} else {
					q.setAt( "path", rows, "/" );
				}
			}
		}

		return q;
	}

	/**
	 * Attempts to stream the given S3 key to a local file path. This
	 * is the preferred method for getting objects as involves little/no
	 * mem consumption.
	 *
	 */
	public void getObject( String key, String filePath ) {
		_s3Client.getObject( _buildGetObjectRequest( key ), Paths.get( filePath ) );
	}

	/**
	 * Attempts to get the given s3 object as a binary object. Prefer getObject( key, filepath )
	 * and use that instead where possible.
	 *
	 */
	public byte[] getObject( String key ) {
		return _s3Client.getObjectAsBytes( _buildGetObjectRequest( key ) ).asByteArray();
	}

	/**
	 * Gets size + last modified date of an object
	 *
	 */
	public Struct getObjectInfo( String key ) {
		HeadObjectResponse resp = _s3Client.headObject( HeadObjectRequest.builder().bucket( _bucket ).key( key ).build() );

		Struct s = CFMLEngineFactory.getInstance().getCreationUtil().createStruct();

		s.put( "size"        , resp.contentLength()             );
		s.put( "lastmodified", Date.from( resp.lastModified() ) );

		return s;
	}

	/**
	 * Does what it says...
	 *
	 */
	public void deleteObject( String key ) {
		_s3Client.deleteObject( DeleteObjectRequest.builder().key( key ).bucket( _bucket ).build() );
	}

	/**
	 * Put an object into the bucket from a local file. This is the preferred performant method.
	 *
	 */
	public void putObject( String key, String localFilePath, String mimetype, String disposition, boolean isPrivate, boolean isTrashed ) {
		_s3Client.putObject( _buildPutObjectRequest( key, mimetype, disposition, isPrivate, isTrashed ), Paths.get( localFilePath ) );
	}

	/**
	 * Put an object into the bucket from a binary byte array. This is not the preferred method.
	 *
	 */
	public void putObject( String key, byte[] bytes, String mimetype, String disposition, boolean isPrivate, boolean isTrashed ) {
		_s3Client.putObject( _buildPutObjectRequest( key, mimetype, disposition, isPrivate, isTrashed ), RequestBody.fromBytes( bytes ) );
	}

	/**
	 * Moves an object from one location to another
	 * with new permissions based on whether private and trashed
	 */
	public void moveObject( String sourceKey, String targetKey, String mimetype, String disposition, boolean isPrivate, boolean isTrashed ) {
		_s3Client.copyObject( _buildCopyObjectRequest( sourceKey, targetKey, mimetype, disposition, isPrivate, isTrashed ) );
		deleteObject( sourceKey );
	}

// PRIVATE HELPERS
	private GetObjectRequest _buildGetObjectRequest( String key ) {
		return GetObjectRequest.builder().key( key ).bucket( _bucket ).build();
	}

	private PutObjectRequest _buildPutObjectRequest( String key, String mimetype, String disposition, boolean isPrivate, boolean isTrashed ) {
		return PutObjectRequest.builder()
		                       .bucket( _bucket )
		                       .key( key )
		                       .contentType( mimetype )
		                       .contentDisposition( disposition )
		                       .acl( ( isPrivate || isTrashed ) ? ObjectCannedACL.PRIVATE : ObjectCannedACL.PUBLIC_READ )
		                       .storageClass( isTrashed ? StorageClass.REDUCED_REDUNDANCY : StorageClass.STANDARD )
		                       .build();
	}

	private CopyObjectRequest _buildCopyObjectRequest( String sourceKey, String targetKey, String mimetype, String disposition, boolean isPrivate, boolean isTrashed ) {
		return CopyObjectRequest.builder()
		                        .sourceBucket( _bucket )
		                        .sourceKey( sourceKey )
		                        .destinationBucket( _bucket )
		                        .destinationKey( targetKey )
		                        .contentType( mimetype )
		                        .contentDisposition( disposition )
		                        .acl( ( isPrivate || isTrashed ) ? ObjectCannedACL.PRIVATE : ObjectCannedACL.PUBLIC_READ )
		                        .storageClass( isTrashed ? StorageClass.REDUCED_REDUNDANCY : StorageClass.STANDARD )
		                        .build();
	}
}