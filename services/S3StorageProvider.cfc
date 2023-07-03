/**
 * Implementation of the [[api-storageprovider]] interface to provide an S3 based
 * storage provider.
 *
 * @singleton
 * @presideService
 * @autodoc
 * @fileSystemSupport
 */
component implements="preside.system.services.fileStorage.StorageProvider" displayname="File System Storage Provider" {

// CONSTRUCTOR
	public any function init(
		  required string s3bucket
		, required string s3accessKey
		, required string s3secretKey
		,          string s3region          = "us-west-1"
		,          string s3rootUrl
		,          string s3subpath         = ""
		,          string s3publicRootPath  = "/public"
		,          string s3privateRootPath = "/private"
		,          string s3trashRootPath   = "/.trash"
	){
		_setRegion( arguments.s3region );
		_setBucket( arguments.s3bucket );
		_setPublicDirectory( arguments.s3subpath & arguments.s3publicRootPath );
		_setPrivateDirectory( arguments.s3subpath & arguments.s3privateRootPath );
		_setTrashDirectory( arguments.s3subpath & arguments.s3trashRootPath );

		if ( !StructKeyExists( arguments, "s3rootUrl" ) ) {
			arguments.s3RootUrl = "https://s3-#arguments.s3region#.amazonaws.com/#arguments.s3Bucket##_getPublicDirectory()#";
		}

		_setRootUrl( arguments.s3rootUrl );
		_setupS3Service( arguments.s3accessKey, arguments.s3secretKey, arguments.s3region, arguments.s3Bucket );

		return this;
	}

// PUBLIC API METHODS
	public any function validate( required struct configuration, required any validationResult ) {
		var bucket    = arguments.configuration.s3bucket    ?: "";
		var s3Service = _instantiateS3Service(
			  accessKey = arguments.configuration.s3accessKey ?: ""
			, secretKey = arguments.configuration.s3secretKey ?: ""
			, region    = arguments.configuration.s3region    ?: "us-west-1"
			, bucket    = arguments.configuration.s3Bucket    ?: ""
		);
		var hasAccess = false;

		try {
			hasAccess = s3Service.checkBucketAccess();
		} catch( any e ) {
			validationResult.addError( "s3accessKey", "storage-providers.s3:validation.connection.error" );
			return;
		}

		if ( !hasAccess ) {
			validationResult.addError( "s3accessKey", "storage-providers.s3:validation.connection.error" );
			return;
		}
	}

	public query function listObjects( required string path, boolean private=false ){
		return _getS3Service().listObjects( _expandPath( argumentCollection=arguments ) );
	}


	public struct function getObjectInfo( required string path, boolean trashed=false, boolean private=false ){
		try {
			return _getS3Service().getObjectInfo( _expandPath( argumentCollection=arguments ) );
		} catch( any e ) {}

		return {};
	}

	public boolean function objectExists( required string path, boolean trashed=false, boolean private=false ){
		return !StructIsEmpty( getObjectInfo( argumentCollection=arguments ) );
	}

	public binary function getObject( required string path, boolean trashed=false, boolean private=false ){
		var cacheKey = _getCacheKey( argumentCollection=arguments );
		var fromCache = _getFromCache( cacheKey );

		if ( !IsNull( local.fromCache ) ) {
			return fromCache;
		}

		try {
			var binaryObject = _getS3Service().getObject( _expandPath( argumentCollection=arguments ) );
		} catch ( any e ) {
			throw(
				  type    = "storageProvider.objectNotFound"
				, message = "The object, [#arguments.path#], could not be found or is not accessible"
			);
		}

		_setToCache( cacheKey, binaryObject );

		return binaryObject;
	}

	public string function getObjectLocalPath( required string path, boolean trashed=false, boolean private=false ) {
		var cacheKey = _getCacheKey( argumentCollection=arguments );

		if ( _existsInCache( cacheKey ) ) {
			return _getCachePath( cacheKey );
		}

		var tmpFilePath = GetTempDirectory() & CreateUUId() & "." & ListLast( arguments.path, "." );

		try {
			_getS3Service().getObject( _expandPath( argumentCollection=arguments ), tmpFilePath );
		} catch ( any e ) {
			throw(
				  type    = "storageProvider.objectNotFound"
				, message = "The object, [#arguments.path#], could not be found or is not accessible"
			);
		}

		if ( FileExists( tmpFilePath ) ) {
			_setToCache( cacheKey, tmpFilePath );
			return tmpFilePath;
		}

		throw(
			  type    = "storageProvider.objectNotFound"
			, message = "The object, [#arguments.path#], could not be found or is not accessible"
		);
	}

	public void function putObject( required any object, required string path, boolean private=false ){
		var dispoAndMime = _getDispositionAndMimeType( ListLast( arguments.path, "/" ) );

		_getS3Service().putObject( _expandPath( argumentCollection=arguments ), arguments.object, dispoAndMime.mimeType, dispoAndMime.disposition, arguments.private, false  );

		var cacheKey = _getCacheKey( argumentCollection=arguments );
		_setToCache( cacheKey, arguments.object );
	}

	public void function putObjectFromLocalPath( required string localPath, required string path, boolean private=false ) {
		var dispoAndMime = _getDispositionAndMimeType( ListLast( arguments.path, "/" ) );

		_getS3Service().putObject( _expandPath( argumentCollection=arguments ), arguments.localPath, dispoAndMime.mimeType, dispoAndMime.disposition, arguments.private, false  );

		var cacheKey = _getCacheKey( argumentCollection=arguments );
		_setToCache( cacheKey, arguments.localPath );
	}

	public void function deleteObject( required string path, boolean trashed=false, boolean private=false ){
		_getS3Service().deleteObject( _expandPath( argumentCollection=arguments ) );
		_clearFromCache( _getCacheKey( argumentCollection=arguments ) );
	}

	public string function softDeleteObject( required string path, boolean private=false ){
		var originalPath = _expandPath( argumentCollection=arguments );
		var newPath      = _expandPath( argumentCollection=arguments, trashed=true );
		var dispoAndMime = _getDispositionAndMimeType( ListLast( newPath, "/" ) );

		_getS3Service().moveObject(
			  originalPath             // sourceKey
			, newPath                  // targetKey
			, dispoAndMime.mimeType    // mimetype
			, dispoAndMime.disposition // disposition
			, true                     // isPrivate
			, true                     // isTrashed
		);

		_clearFromCache( _getCacheKey( argumentCollection=arguments ) );

		return arguments.path;
	}

	public boolean function restoreObject( required string trashedPath, required string newPath, boolean private=false ){
		var originalPath = _expandPath( argumentCollection=arguments, path=arguments.trashedPath, trashed=true );
		var newPath      = _expandPath( argumentCollection=arguments, path=arguments.newPath    , trashed=false );
		var dispoAndMime = _getDispositionAndMimeType( ListLast( newPath, "/" ) );

		_getS3Service().moveObject(
			  originalPath             // sourceKey
			, newPath                  // targetKey
			, dispoAndMime.mimeType    // mimetype
			, dispoAndMime.disposition // disposition
			, arguments.private        // isPrivate
			, false                     // isTrashed
		);

		return true;
	}

	public void function moveObject( required string originalPath, required string newPath, boolean originalIsPrivate=false, boolean newIsPrivate=false ) {
		var originalPath = _expandPath( path=arguments.originalPath, private=originalIsPrivate );
		var newPath      = _expandPath( path=arguments.newPath     , private=newIsPrivate );
		var dispoAndMime = _getDispositionAndMimeType( ListLast( newPath, "/" ) );

		_getS3Service().moveObject(
			  originalPath             // sourceKey
			, newPath                  // targetKey
			, dispoAndMime.mimeType    // mimetype
			, dispoAndMime.disposition // disposition
			, arguments.newIsPrivate   // isPrivate
			, false                    // isTrashed
		);

		_clearFromCache( _getCacheKey( path=arguments.originalPath, private=originalIsPrivate ) );
	}

	public string function getObjectUrl( required string path ){
		var rootUrl = _getRootUrl();

		if ( Trim( rootUrl ).len() ) {
			return rootUrl & _cleanPath( arguments.path );
		}

		return "";
	}

// PRIVATE HELPERS
	private void function _setupS3Service(
		  required string accessKey
		, required string secretKey
		, required string region
		, required string bucket
	) {
		_setS3Service( _instantiateS3Service( argumentCollection=arguments ) );
	}

	private string function _expandPath( required string path, boolean trashed=false, boolean private=false ){
		var relativePath = _cleanPath( arguments.path, arguments.trashed, arguments.private );
		var rootPath     = arguments.trashed ? _getTrashDirectory() : ( arguments.private ? _getPrivateDirectory() : _getPublicDirectory() );

		return ReReplace( rootPath & relativePath, "^/", "" );
	}

	private string function _cleanPath( required string path, boolean trashed=false, boolean private=false ){
		var cleaned = ListChangeDelims( arguments.path, "/", "\" );

		cleaned = ReReplace( cleaned, "^/", "" );
		cleaned = Trim( cleaned );

		return cleaned;
	}

	private void function _ensureDirectoryExists( required string dir ){
		if ( arguments.dir.len() && !DirectoryExists( arguments.dir ) ) {
			try {
				DirectoryCreate( arguments.dir, true, true );
			} catch( any e ) {
				if ( !DirectoryExists( arguments.dir ) ) {
					rethrow;
				}
			}
		}
	}

	private any function _instantiateS3Service(
		  required string accessKey
		, required string secretKey
		, required string region
		, required string bucket
	) {
		_registerOsgiBundle();

		return CreateObject( "java", "org.pixl8.s3storageprovider.Service", "org.pixl8.s3storageprovider" ).init( arguments.region, arguments.bucket, arguments.accesskey, arguments.secretkey );
	}

	private function _registerOsgiBundle() {
		if ( !StructKeyExists( request, "_s3StorageProviderBundleRegistered" ) ) {
			var cfmlEngine = CreateObject( "java", "lucee.loader.engine.CFMLEngineFactory" ).getInstance();
			var osgiUtil   = CreateObject( "java", "lucee.runtime.osgi.OSGiUtil" );
			var lib        = ExpandPath( "/app/extensions/preside-ext-s3-storage-provider/lib/s3storageprovider-1.0.0.jar" );
			var resource   = cfmlEngine.getResourceUtil().toResourceExisting( getPageContext(), lib );

			osgiUtil.installBundle( cfmlEngine.getBundleContext(), resource, true );

			request._s3StorageProviderBundleRegistered = true;
		}
	}

	private any function _getCache() {
		if ( !StructKeyExists( variables, "_cache" ) ) {
			if ( StructKeyExists( application, "cbBootstrap" ) && IsDefined( 'application.cbBootstrap.getController' ) ) {
				variables._cache = application.cbBootstrap.getController().getCachebox().getCache( "s3StorageProviderCache" );
			}
		}

		return variables._cache ?: NullValue();
	}

	private string function _getCacheKey( required string path, boolean private=false, boolean trashed=false ) {
		return _getBucket() & "#arguments.path#.#arguments.private#.#arguments.trashed#";
	}

	private any function _getFromCache() {
		var cache = _getCache();
		if ( !IsNull( local.cache ) ) {
			return cache.get( argumentCollection=arguments );
		}
	}

	private boolean function _existsInCache() {
		var cache = _getCache();
		if ( !IsNull( local.cache ) ) {
			return cache.lookupQuiet( argumentCollection=arguments );
		}
		return false;
	}

	private string function _getCachePath() {
		var cache = _getCache();

		if ( !IsNull( local.cache ) ) {
			return _getCache().getObjectStore().getCacheFilePath( argumentCollection=arguments );
		}

		return "";
	}

	private any function _setToCache() {
		var cache = _getCache();

		if ( !IsNull( local.cache ) ) {
			return cache.set( argumentCollection=arguments );
		}
	}

	private any function _clearFromCache() {
		var cache = _getCache();

		if ( !IsNull( local.cache ) ) {
			return cache.clearQuiet( argumentCollection=arguments );
		}

	}

	private struct function _getDispositionAndMimeType( required string fileName ) {
		var fileExtension = ListLast( arguments.fileName, "." );
		if ( !StructKeyExists( variables, "_extensionMappings" ) || StructIsEmpty( variables._extensionMappings ) ) {
			if ( StructKeyExists( application, "cbBootstrap" ) && IsDefined( 'application.cbBootstrap.getController' ) ) {
				var typeSettings = application.cbBootstrap.getController().getSetting( "assetmanager.types" );
				var extMappings = {};

				for( var group in typeSettings ) {
					for( var ext in typeSettings[ group ] ) {
						var mimeType = typeSettings[ group ][ ext ].mimeType ?: "";
						var serveAsAttachment = IsBoolean( typeSettings[ group ][ ext ].serveAsAttachment ?: "" ) && typeSettings[ group ][ ext ].serveAsAttachment;
						if ( Len( Trim( mimeType ) ) ) {
							extMappings[ ext ] ={
								  mimeType = mimeType
								, disposition = serveAsAttachment ? "attachment" : "inline"
							};
						}
					}
				}

				variables._extensionMappings = extMappings;
			}
		}

		var result = StructCopy( variables._extensionMappings[ fileExtension ] ?: { mimeType="application/octet-stream", disposition="attachment" } );

		if ( result.disposition == "attachment" ) {
			result.disposition = "attachment; filename=""#arguments.fileName#""";
		}

		return result;
	}

// GETTERS AND SETTERS
	private string function _getBucket() {
		return _bucket;
	}
	private void function _setBucket( required string bucket ) {
		_bucket = arguments.bucket;
	}

	private string function _getRegion() {
		return _region;
	}
	private void function _setRegion( required string region ) {
		_region = arguments.region;
	}

	private string function _getPublicDirectory() {
		return _publicDirectory;
	}
	private void function _setPublicDirectory( required string publicDirectory ) {
		_publicDirectory = arguments.publicDirectory;
		if ( Len( Trim( _publicDirectory ) ) && Right( _publicDirectory, 1 ) != "/" ) {
			_publicDirectory &= "/";
		}
	}

	private any function _getPrivateDirectory() {
		return _privateDirectory;
	}
	private void function _setPrivateDirectory( required any privateDirectory ) {
		_privateDirectory = arguments.privateDirectory;
		if ( Len( Trim( _privateDirectory ) ) && Right( _privateDirectory, 1 ) != "/" ) {
			_privateDirectory &= "/";
		}
	}

	private string function _getTrashDirectory(){
		return _trashDirectory;
	}
	private void function _setTrashDirectory( required string trashDirectory ){
		_trashDirectory = arguments.trashDirectory;
		if ( Len( Trim( _trashDirectory ) ) && Right( _trashDirectory, 1 ) != "/" ) {
			_trashDirectory &= "/";
		}
	}

	private string function _getRootUrl(){
		return _rootUrl;
	}
	private void function _setRootUrl( required string rootUrl ){
		_rootUrl = arguments.rootUrl;

		if ( Len( Trim( _rootUrl ) ) && Right( _rootUrl, 1 ) != "/" ) {
			_rootUrl &= "/";
		}
	}

	private any function _getS3Service() {
		return _s3Service;
	}
	private void function _setS3Service( required any s3Service ) {
		_s3Service = arguments.s3Service;
	}

	private any function _getS3Utils() {
		return _s3Utils;
	}
	private void function _setS3Utils( required any s3Utils ) {
		_s3Utils = arguments.s3Utils;
	}

	private any function _getReadPermission() {
		return _readPermission;
	}
	private void function _setReadPermission( required any readPermission ) {
		_readPermission = arguments.readPermission;
	}

	private any function _getPublicGroup() {
		return _publicGroup;
	}
	private void function _setPublicGroup( required any publicGroup ) {
		_publicGroup = arguments.publicGroup;
	}
}
