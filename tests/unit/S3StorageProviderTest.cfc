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
		} );
	}

// HELPERS
	private function _getService(
		  accessKey = application.TEST_S3_ACCESS_KEY
		, secretKey = application.TEST_S3_SECRET_KEY
		, bucket    = application.TEST_S3_BUCKET
		, region    = application.TEST_S3_REGION
	) {
		return new "app.extensions.preside-ext-s3-storage-provider.services.S3StorageProvider"(
			  s3bucket    = arguments.bucket
			, s3accessKey = arguments.accessKey
			, s3secretKey = arguments.secretKey
			, s3region    = arguments.region
			, s3subpath   = "/tests"
		);
	}

}