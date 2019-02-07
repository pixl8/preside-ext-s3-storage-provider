component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupStorageProvider( settings );
		_setupDefaultStorageProviderSettings( settings );
		_setupInterceptors( conf );
	}

// private helpers
	private void function _setupStorageProvider( settings ) {
		settings.storageProviders.s3 = { class = "s3StorageProvider.services.S3StorageProvider" };
	}

	private void function _setupDefaultStorageProviderSettings( settings ) {
		settings.s3StorageProvider = settings.s3StorageProvider ?: {};

		settings.s3StorageProvider.append( {
			  accessKey = settings.injectedConfig.S3_ASSETS_ACCESS_KEY ?: ""
			, secretKey = settings.injectedConfig.S3_ASSETS_SECRET_KEY ?: ""
			, region    = settings.injectedConfig.S3_ASSETS_REGION     ?: "us-east-1"
			, bucket    = settings.injectedConfig.S3_ASSETS_BUCKET     ?: ""
			, subpath   = settings.injectedConfig.S3_ASSETS_SUBPATH    ?: ""
			, rootUrl   = settings.injectedConfig.S3_ASSETS_URL        ?: "https://s3.#( settings.s3StorageProvider.region ?: ( settings.injectedConfig.S3_ASSETS_REGION ?: "us-east-1" ) )#.amazonaws.com"
		}, false );
	}

	private void function _setupInterceptors( conf ) {
		conf.interceptors.append( {
			  class      = "app.extensions.preside-ext-s3-storage-provider.interceptors.S3StorageProviderInterceptors"
			, properties = {}
		});
	}
}
