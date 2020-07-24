component {


	public void function configure( binder ) {
		var s3StorageSettings = binder.getColdbox().getSetting( "s3StorageProvider" );
		var args = {
			  s3bucket    = s3StorageSettings.bucket    ?: ""
			, s3accessKey = s3StorageSettings.accessKey ?: ""
			, s3secretKey = s3StorageSettings.secretKey ?: ""
			, s3region    = s3StorageSettings.region    ?: "us-east-1"
			, s3subpath   = s3StorageSettings.subpath   ?: ""
		};

		if ( StructKeyExists( s3StorageSettings, "rootUrl" ) ) {
			args.s3RootUrl = s3StorageSettings.rootUrl;
		}

		if ( Len( args.s3accessKey ) && Len( args.s3secretKey ) && Len( args.s3bucket ) ) {
			binder.map( "assetStorageProvider" ).asSingleton().to( "s3StorageProvider.services.S3StorageProvider" ).noAutoWire().initWith( argumentCollection=args );
			binder.map( "formBuilderStorageProvider" ).asSingleton().to( "s3StorageProvider.services.S3StorageProvider" ).noAutoWire().initWith(
				  argumentCollection = args
				, s3subPath          = ListAppend( args.s3subPath, "formbuilder", "/" )
			);
			binder.map( "scheduledReportStorageProvider" ).asSingleton().to( "s3StorageProvider.services.S3StorageProvider" ).noAutoWire().initWith(
				  argumentCollection = args
				, s3subPath          = ListAppend( args.s3subPath, "scheduledreports", "/" )
				, s3publicRootPath   = "/"
				, s3privateRootPath  = "/"
			);
		}
	}

}