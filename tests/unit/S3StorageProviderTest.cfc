component extends="testbox.system.BaseSpec" {

	function run() {
		describe( title="validate()", body=function(){
			it( "should add a validation error when the credentials fail to work", function(){
				var svc = _getService();
				var validationResult = new preside.system.services.validation.ValidationResult();

				svc.validate( {
					  s3accessKey="xxx"
					, s3secretKey="xxx"
				}, validationResult );

				var messages = validationResult.getMessages();

				expect( messages.s3accesskey.message ?: "" ).toBe( "storage-providers.s3:validation.connection.error" );
			} );
			it( "should add a validation error when the credentials are correct but the bucket does not exist (or user does not have access)", function(){
				var svc = _getService();
				var validationResult = new preside.system.services.validation.ValidationResult();

				svc.validate( {
					  s3accessKey = application.TEST_S3_ACCESS_KEY
					, s3secretKey = application.TEST_S3_SECRET_KEY
					, s3Bucket    = CreateUUId()
				}, validationResult );

				var messages = validationResult.getMessages();

				expect( messages.s3bucket.message ?: "" ).toBe( "storage-providers.s3:validation.bucket.error" );
			} );
			it( "should add a validation error when the credentials are correct but the bucket region is different to the configured region", function(){
				var svc = _getService();
				var validationResult = new preside.system.services.validation.ValidationResult();
				var dummyRegion = "us-east-1";

				if ( dummyRegion == application.TEST_S3_REGION ) {
					dummyRegion = "eu-west-1";
				}

				svc.validate( {
					  s3accessKey = application.TEST_S3_ACCESS_KEY
					, s3secretKey = application.TEST_S3_SECRET_KEY
					, s3Bucket    = application.TEST_S3_BUCKET
					, s3Region    = dummyRegion
				}, validationResult );

				var messages = validationResult.getMessages();

				expect( messages.s3region.message ?: "" ).toBe( "storage-providers.s3:validation.region.error" );
			} );
			it( "should do nothing when credentials are correct", function(){
				var svc = _getService();
				var validationResult = new preside.system.services.validation.ValidationResult();

				svc.validate( {
					  s3accessKey = application.TEST_S3_ACCESS_KEY
					, s3secretKey = application.TEST_S3_SECRET_KEY
					, s3region    = application.TEST_S3_REGION
					, s3bucket    = application.TEST_S3_BUCKET
				}, validationResult );

				var messages = validationResult.getMessages();

				expect( StructCount( messages ) ).toBe( 0 );
			} );
		});

		describe( "listObjects", function(){
			it( "should return a query of all public objects matching the supplied prefix", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var objPaths = [ "#CreateUUId()#.png", "#CreateUUId()#.png", "#CreateUUId()#.png" ];
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				for( var path in objPaths ) {
					svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/#path#", private=false );
				}

				var listed = svc.listObjects( "/" & prefix & "/" );
				expect( listed.recordCount ).toBe( 3 );
				for( var l in listed ) {
					expect( l.size ).toBe( 4255 );
					expect( l.path ).toBe( "/tests/public/#prefix#" );
					expect( ArrayFind( objPaths, l.name ) > 0 ).toBeTrue();
				}
			} );

			it( "should return a query of all private objects matching the supplied prefix", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var objPaths = [ "#CreateUUId()#.png", "#CreateUUId()#.png", "#CreateUUId()#.png" ];
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				for( var path in objPaths ) {
					svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/#path#", private=true );
				}

				var listed = svc.listObjects( path="/" & prefix & "/", private=true );
				expect( listed.recordCount ).toBe( 3 );
				for( var l in listed ) {
					expect( l.size ).toBe( 4255 );
					expect( l.path ).toBe( "/tests/private/#prefix#" );
					expect( ArrayFind( objPaths, l.name ) > 0 ).toBeTrue();
				}
			} );

			it( "should return an empty query when no files match the passed prefix", function(){
				var svc = _getService();
				var listed = svc.listObjects( path="/#CreateUUId()#/" );
				expect( listed.recordCount ).toBe( 0 );
			} );
		} );

		describe( "getObjectInfo()", function(){
			it( "should return a struct with datemodified and size of the matching public file", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=false );

				var result = svc.getObjectInfo( path="/" & prefix & "/test.png" );

				expect( result.size ).toBe( 4255 );
				expect( result.lastmodified ).toBeDate();
			} );
			it( "should return a struct with datemodified and size of the matching private file", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=true );

				var result = svc.getObjectInfo( path="/" & prefix & "/test.png", private=true );

				expect( result.size ).toBe( 4255 );
				expect( result.lastmodified ).toBeDate();
			} );
			it( "should return an empty struct when object does not exist", function(){
				var svc = _getService();
				var result = svc.getObjectInfo( path="/#CreateUUId()#/nonexistantobject.png" );

				expect( result ).toBe( {} );
			} );
		} );

		describe( "objectExists", function(){
			it( "should return true when public object exists", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=false );

				expect( svc.objectExists( path="/" & prefix & "/test.png" ) ).toBeTrue();
			} );
			it( "should return true when private object exists", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=true );

				expect( svc.objectExists( path="/" & prefix & "/test.png", private=true ) ).toBeTrue();
			} );
			it( "should return false when object does not exist", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=true );

				expect( svc.objectExists( path="/" & prefix & "/test.png", private=false ) ).toBeFalse();
			} );
		} );

		describe( "getObject", function(){
			it( "should return matched public object binary", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=false );

				var result = svc.getObject( path="/" & prefix & "/test.png" );

				expect( isBinary( result ) ).toBeTrue();
				expect( Len( result ) ).toBe( 4255 );
			} );
			it( "should return matched private object binary", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=true );

				var result = svc.getObject( path="/" & prefix & "/test.png", private=true );

				expect( isBinary( result ) ).toBeTrue();
				expect( Len( result ) ).toBe( 4255 );
			} );
			it( "should throw informative error when object does not exist", function(){
				var svc = _getService();

				expect( function(){
					svc.getObject( path="/#CreateUUId()#/nonexistantobject.pdf", private=false );
				} ).toThrow( type="storageProvider.objectNotFound" );
 			} );
		} );

		describe( "getObjectLocalPath", function(){
			it( "should return matched public object to a local file", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=false );

				var result = svc.getObjectLocalPath( path="/" & prefix & "/test.png" );
				expect( FileExists( result ) ).toBeTrue();
				var fileInfo = GetFileInfo( result );
				expect( fileInfo.size ).toBe( 4255 );
			} );
			it( "should return matched private object binary", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=true );

				var result = svc.getObjectLocalPath( path="/" & prefix & "/test.png", private=true );

				expect( FileExists( result ) ).toBeTrue();
				var fileInfo = GetFileInfo( result );
				expect( fileInfo.size ).toBe( 4255 );
			} );
			it( "should throw informative error when object does not exist", function(){
				var svc = _getService();

				expect( function(){
					svc.getObjectLocalPath( path="/#CreateUUId()#/nonexistantobject.pdf", private=false );
				} ).toThrow( type="storageProvider.objectNotFound" );
 			} );
		} );

		describe( "deleteObject", function(){
			it( "should fully delete the given obect from the s3 bucket", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=false );
				expect( svc.objectExists( "/#prefix#/test.png" ) ).toBeTrue();
				var objUrl = svc.getObjectUrl( "/#prefix#/test.png" );
				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				svc.deleteObject( "/#prefix#/test.png" );
				expect( svc.objectExists( "/#prefix#/test.png" ) ).toBeFalse();
				expect( svc.objectExists( path="/#prefix#/test.png", private=true ) ).toBeFalse();
				expect( svc.objectExists( path="/#prefix#/test.png", trashed=true ) ).toBeFalse();

				var result = "";
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) == 404 || Val( result.statuscode ) == 403 ).toBeTrue();
			} );
		} );

		describe( "putObjectFromLocalPath", function(){
			it( "should put object into S3 where it is publically accessible (when private=false)", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=false );
				var objUrl = svc.getObjectUrl( "/#prefix#/test.png" );
				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( result.mimetype ).toBe( "image/png" );
				expect( Val( result.statuscode ) ).toBe( 200 );
				expect( isBinary( result.filecontent ) ).toBeTrue();
				expect( Len( result.filecontent ) ).toBe( 4255 );
			} );

			it( "should set content disposition headers for downloadable file types", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.pdf" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.pdf", private=false );
				var objUrl = svc.getObjectUrl( "/#prefix#/test.pdf" );
				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( result.mimetype ).toBe( "application/pdf" );
				expect( result.header contains "Content-Disposition: attachment; filename=""test.pdf""").toBeTrue();
				expect( Val( result.statuscode ) ).toBe( 200 );
				expect( isBinary( result.filecontent ) ).toBeTrue();
				expect( Len( result.filecontent ) ).toBe( 7320 );
			} );

			it( "should auto set mimetype and content disposition", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );


				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=false );
				var objUrl = svc.getObjectUrl( "/#prefix#/test.png" );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
			} );

			it( "should put object into S3 where it is not publically accessible (when private=true)", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=true );
				var objUrl = Replace( svc.getObjectUrl( "/#prefix#/test.png" ), "/public/", "/private/" );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 403 );
				expect( result.filecontent contains "access denied" ).toBeTrue();
			} );
		} );

		describe( "putObject", function(){
			it( "should put object into S3 where it is publically accessible (when private=false)", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = FileReadBinary( ExpandPath( "/tests/fixtures/test.png" ) );

				svc.putObject( object=sourceFile, path="/#prefix#/test.png", private=false );
				var objUrl = svc.getObjectUrl( "/#prefix#/test.png" );
				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 200 );
				expect( isBinary( result.filecontent ) ).toBeTrue();
				expect( Len( result.filecontent ) ).toBe( 4255 );
			} );

			it( "should put object into S3 where it is not publically accessible (when private=true)", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = FileReadBinary( ExpandPath( "/tests/fixtures/test.png" ) );

				svc.putObject( object=sourceFile, path="/#prefix#/test.png", private=true );
				var objUrl = Replace( svc.getObjectUrl( "/#prefix#/test.png" ), "/public/", "/private/" );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 403 );
				expect( result.filecontent contains "access denied" ).toBeTrue();
			} );
		} );

		describe( "moveObject", function(){
			it( "should move objects between public source and destination paths", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );
				var sourcePath = "/#prefix#/test.png";
				var targetPath = "/#prefix#/#CreateUUId()#.png";

				svc.putObjectFromLocalPath( localPath=sourceFile, path=sourcePath, private=false );

				expect( svc.objectExists( sourcePath ) ).toBe( true );
				expect( svc.objectExists( targetPath ) ).toBe( false );

				svc.moveObject( "/#prefix#/test.png", targetPath )

				expect( svc.objectExists( sourcePath ) ).toBe( false );
				expect( svc.objectExists( targetPath ) ).toBe( true );

				var objUrl = svc.getObjectUrl( targetPath );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				sleep( 200 );
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 200 );
			} );

			it( "should move objects from private source to public destination paths", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );
				var sourcePath = "/#prefix#/test.png";
				var targetPath = "/#prefix#/#CreateUUId()#.png";

				svc.putObjectFromLocalPath( localPath=sourceFile, path=sourcePath, private=true );

				expect( svc.objectExists( path=sourcePath, private=true ) ).toBe( true );
				expect( svc.objectExists( targetPath ) ).toBe( false );

				svc.moveObject(
					  originalPath      = "/#prefix#/test.png"
					, newPath           = targetPath
					, originalIsPrivate = true
					, newIsPrivate      = false
				);

				expect( svc.objectExists( path=sourcePath, private=true ) ).toBe( false );
				expect( svc.objectExists( targetPath ) ).toBe( true );

				var objUrl = svc.getObjectUrl( targetPath );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				sleep( 200 );
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 200 );
			} );

			it( "should move objects from public source to private destination paths", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );
				var sourcePath = "/#prefix#/test.png";
				var targetPath = "/#prefix#/#CreateUUId()#.png";

				svc.putObjectFromLocalPath( localPath=sourceFile, path=sourcePath );

				expect( svc.objectExists( path=sourcePath, private=false ) ).toBe( true );
				expect( svc.objectExists( path=targetPath, private=true ) ).toBe( false );

				svc.moveObject(
					  originalPath      = "/#prefix#/test.png"
					, newPath           = targetPath
					, originalIsPrivate = false
					, newIsPrivate      = true
				);

				expect( svc.objectExists( path=sourcePath, private=false ) ).toBe( false );
				expect( svc.objectExists( path=targetPath, private=true ) ).toBe( true );

				var objUrl = Replace( svc.getObjectUrl( targetPath ), "/public/", "/private/" );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				sleep( 200 );
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 403 );
			} );
		} );

		describe( "softDeleteObject", function(){
			it( "should move the provided object to the .trash folder", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );
				var sourcePath = "/#prefix#/test.png";

				svc.putObjectFromLocalPath( localPath=sourceFile, path=sourcePath );

				expect( svc.objectExists( path=sourcePath, private=false ) ).toBe( true );

				svc.softDeleteObject( sourcePath );

				expect( svc.objectExists( path=sourcePath, private=false ) ).toBe( false );
				expect( svc.objectExists( path=sourcePath, trashed=true ) ).toBe( true );

				var objUrl = Replace( svc.getObjectUrl( sourcePath ), "/public/", "/.trash/" );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 403 );
			} );
		} );

		describe( "restoreObject", function(){
			it( "should move the provided object out of the .trash folder into the target path", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );
				var sourcePath = "/#prefix#/test.png";
				var newPath = "/#prefix#/test.png";

				svc.putObjectFromLocalPath( localPath=sourceFile, path=sourcePath );

				expect( svc.objectExists( path=sourcePath, private=false ) ).toBe( true );

				svc.softDeleteObject( sourcePath );

				expect( svc.objectExists( path=sourcePath, private=false ) ).toBe( false );
				expect( svc.objectExists( path=sourcePath, trashed=true ) ).toBe( true );

				svc.restoreObject( trashedPath=sourcePath, newPath=newPath, private=false );

				expect( svc.objectExists( path=sourcePath, private=false ) ).toBe( true );
				expect( svc.objectExists( path=sourcePath, trashed=true ) ).toBe( false );

				var objUrl = svc.getObjectUrl( sourcePath );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 200 );
			} );
		} );

		describe( "getTemporaryPrivateObjectUrl", function(){
			it( "should provide a temporary URL for downloading otherwise private access objects", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = FileReadBinary( ExpandPath( "/tests/fixtures/test.png" ) );

				svc.putObject( object=sourceFile, path="/#prefix#/test.png", private=true );
				var objUrl = Replace( svc.getObjectUrl( "/#prefix#/test.png" ), "/public/", "/private/" );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				expect( Val( result.statuscode ) ).toBe( 403 );
				expect( result.filecontent contains "access denied" ).toBeTrue();

				objUrl = svc.getTemporaryPrivateObjectUrl( "/#prefix#/test.png" );

				expect( objUrl contains "amazonaws.com" ).toBeTrue();
				http url=objUrl timeout=10 result="result";
				debug( objUrl );
				debug( result );
				expect( Val( result.statuscode ) ).toBe( 200 );
				expect( isBinary( result.filecontent ) ).toBeTrue();
				expect( Len( result.filecontent ) ).toBe( 4255 );
			} );
		} );
	}

// HELPERS
	private function _getService(
		  accessKey = application.TEST_S3_ACCESS_KEY
		, secretKey = application.TEST_S3_SECRET_KEY
		, bucket    = application.TEST_S3_BUCKET
		, region    = application.TEST_S3_REGION
	) {
		var svc = CreateMock( object=new "app.extensions.preside-ext-s3-storage-provider.services.S3StorageProvider"(
			  s3bucket    = arguments.bucket
			, s3accessKey = arguments.accessKey
			, s3secretKey = arguments.secretKey
			, s3region    = arguments.region
			, s3subpath   = "/tests"
		) );

		var cache    = createStub();
		var objStore = createStub();

		cache.$( "get" );
		cache.$( "lookupQuiet", false );
		cache.$( "clearQuiet" );
		cache.$( "getObjectStore", objStore );
		objStore.$( method="getCacheFilePath", callBack=function( key ){
			return GetTempDirectory() & Hash( arguments.key ) & ".cache";
		} );
		cache.$( method="set", callBack=function( key, object ){
			var thisFilePath = GetTempDirectory() & Hash( arguments.key ) & ".cache";
			if ( IsSimpleValue( arguments.object ) && FileExists( arguments.object ) ) {
				FileCopy( arguments.object, thisFilePath );
			} else {
				FileWrite( thisFilePath, arguments.object );
			}
		} );

		svc.$( "_getCache", cache );
		svc.$( method="_getDispositionAndMimeType", callback=function( filename ){
			var filetype = ListLast( arguments.filename, "." );
			if ( filetype == "pdf" ) {
				return { disposition="attachment; filename=""#arguments.filename#""", mimetype="application/pdf" };
			}
			return { disposition="inline", mimetype="image/#filetype#" };
		} );

		return svc;
	}
}