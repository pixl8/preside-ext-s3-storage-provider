#!/bin/bash

rm -rf artifacts/*
mvn package || exit 1
cd artifacts
unzip s3storageprovider-1.0.0.jar
echo "Manifest-Version: 1.0
Bundle-ManifestVersion: 2
Bundle-Name: Preside S3 Storage Provider helper using AWS SDK
Bundle-SymbolicName: org.pixl8.s3storageprovider
Bundle-Version: 1.0.0
" > META-INF/MANIFEST.MF
rm s3storageprovider-1.0.0.jar
zip -rq s3storageprovider-1.0.0.jar *

cp s3storageprovider-1.0.0.jar ../../lib/
