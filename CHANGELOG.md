# Changelog

## 1.0.0

* Support for Preside 10.14 'file system' storage provider methods that allow operations just on local file paths, rather than binary objects loaded into memory.
* Support using the AWS CLI to perform GETs and PUTs of objects rather than the Java API - minimize java memory usage

## 0.9.11

* [#4](https://github.com/pixl8/preside-ext-s3-storage-provider/issues/4) ensure mimetype and content disposition is correctly set when moving an object

## 0.9.10

* Ensure the new Preside 10.12 "ScheduledExportStorageProvider" is automatically converted to S3


## 0.9.9

* Use more compatible mapping in wirebox.cfc (we have a problem with load order sometimes we think)

## 0.9.8

* Ensure the new Preside 10.12 "ScheduledReportStorageProvider" is automatically converted to S3

## 0.9.7

* Do not use Lucee temp directory for file based cache.

## 0.9.6

* Fix objectExists() throwing an error rather than returning false when object does not exist in storage

## 0.9.5

* Remove accidentally added code (out of place)

## 0.9.4

* Ensure formbuilder storage provider is mapped to s3!

## 0.9.3

* Change how public URLs are set. Now must either pass nothing for automatic public URL generation, or pass an explicity URL including the subpath to the public folder.
* Do not lowercase all filenames
* Fix bad argument names that break with the admin GUI setup of asset manager storage providers

## 0.9.2

* Fix fieldnames for form validation


## 0.9.1

* Remove dependency on S3SDK (not feature complete enough). Use jets3t that comes with Lucee instead.

## 0.9.0

* First draft working storage provider
