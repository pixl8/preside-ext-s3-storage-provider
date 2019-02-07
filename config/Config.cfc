component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		_setupStorageProvider( settings );
	}

// private helpers
	private void function _setupStorageProvider( settings ) {
		settings.storageProviders.s3 = { class = "s3StorageProvider.services.S3StorageProvider" };
	}

}
