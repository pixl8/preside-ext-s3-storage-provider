component {
	this.name = "S3 Storage Provider Test suite";

	this.mappings[ '/tests'                                          ] = ExpandPath( "/" );
	this.mappings[ '/testbox'                                        ] = ExpandPath( "/testbox" );
	this.mappings[ '/app/extensions/preside-ext-s3-storage-provider' ] = ExpandPath( "../" );
	this.mappings[ '/preside'                                        ] = ExpandPath( "/preside" );
	this.mappings[ '/coldbox'                                        ] = ExpandPath( "/preside/system/externals/coldbox" );

	setting requesttimeout="6000";

	public void function onRequest( required string requestedTemplate ) output=true {
		if ( !_checkTestCredentials() ) {
			include template="nocredsset.cfm";
		} else {
			include template=arguments.requestedTemplate;
		}
	}

	function _checkTestCredentials() {
		if ( !StructKeyExists( application, "_credentialsVerified" ) || !application._credentialsVerified ) {
			var env = CreateObject("java", "java.lang.System").getEnv();

			application.TEST_S3_ACCESS_KEY = Trim( env.TEST_S3_ACCESS_KEY ?: "" );
			application.TEST_S3_SECRET_KEY = Trim( env.TEST_S3_SECRET_KEY ?: "" );
			application.TEST_S3_BUCKET     = Trim( env.TEST_S3_BUCKET     ?: "" );
			application.TEST_S3_REGION     = Trim( env.TEST_S3_REGION     ?: "" );

			application._credentialsVerified = Len( application.TEST_S3_ACCESS_KEY ) &&
			                                   Len( application.TEST_S3_SECRET_KEY ) &&
			                                   Len( application.TEST_S3_BUCKET     ) &&
			                                   Len( application.TEST_S3_REGION     );
		}

		header statuscode=500;

		return application._credentialsVerified;
	}
}
