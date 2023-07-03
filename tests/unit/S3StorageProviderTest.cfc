component extends="testbox.system.BaseSpec" {

	function run() {
		describe( title="validate()", body=function(){
			it( "should add a validation error when the credentials fail to work", function(){
				var svc = _getService();
				var validationResult = new preside.system.services.validation.ValidationResult();

				svc.validate( { s3accessKey="xxx", s3secretKey="xxx" }, validationResult );

				var messages = validationResult.getMessages();

				expect( messages.s3accesskey.message ?: "" ).toBe( "storage-providers.s3:validation.connection.error" );
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
debug( result )
				expect( FileExists( result ) ).toBeTrue();
				var fileInfo = GetFileInfo( result );
				debug( fileInfo );
			} );
			it( "should return matched private object binary", function(){
				var svc = _getService();
				var prefix = CreateUUId();
				var sourceFile = ExpandPath( "/tests/fixtures/test.png" );

				svc.putObjectFromLocalPath( localPath=sourceFile, path="/#prefix#/test.png", private=true );

				var result = svc.getObjectLocalPath( path="/" & prefix & "/test.png", private=true );

				expect( FileExists( result ) ).toBeTrue();
				var fileInfo = GetFileInfo( result );
				debug( fileInfo );
			} );
			it( "should throw informative error when object does not exist", function(){
				var svc = _getService();

				expect( function(){
					svc.getObjectLocalPath( path="/#CreateUUId()#/nonexistantobject.pdf", private=false );
				} ).toThrow( type="storageProvider.objectNotFound" );
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

		return svc;
	}

}