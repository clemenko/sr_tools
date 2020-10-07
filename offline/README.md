# StackRox Offline bits

## Two Options

There are basically two options for importing the bits. A. Use `stackrox_offline.sh` to get the latest. Or B. Consume the latest bits from this repo. Once you have the two tarballs they will need to be uncompressed. Details below.

## Retrieving the latest

There is a shell script, `stackrox_getoffline.sh`, included that will retrieve the scanner vulnerability update and the offline bundle. Edit the username in the file and proceed with downloading.

## Untar the Offline Bundle

In order to consume the offline bundle it will need to be unzipped. Please pay attention to the version number.

```bash
clemenko:clemenko StackRox_offline $ tar -xzvf stackrox_offline_3.0.36.1.tar.gz 
x image-bundle/
x image-bundle/bin/
x image-bundle/scanner.img
x image-bundle/scanner-db.img
x image-bundle/monitoring.img
x image-bundle/import.sh
x image-bundle/README.txt
x image-bundle/main.img
x image-bundle/bin/linux/
x image-bundle/bin/darwin/
x image-bundle/bin/windows/
x image-bundle/bin/windows/roxctl.exe
x image-bundle/bin/darwin/roxctl
x image-bundle/bin/linux/roxctl
clemenko:clemenko StackRox_offline $
```

Once untarred there is another README.txt and an `import_bundle/import.sh` script that will help load the images into the container engine. As well as contain the `roxctl` needed.
