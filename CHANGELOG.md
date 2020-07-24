# Changelog

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
