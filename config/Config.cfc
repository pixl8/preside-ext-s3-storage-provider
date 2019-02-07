component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupStorageProvider( settings );
		_setupInterceptors( conf );
	}

// private helpers
	private void function _setupStorageProvider( settings ) {
		settings.storageProviders.s3 = { class = "s3StorageProvider.services.S3StorageProvider" };
	}

	private void function _setupInterceptors( conf ) {
		conf.interceptors.append( {
			  class      = "app.extensions.preside-ext-s3-storage-provider.interceptors.S3StorageProviderInterceptors"
			, properties = {}
		});

	}

}
