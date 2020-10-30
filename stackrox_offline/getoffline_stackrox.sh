#!/bin/bash

#vars
export version=3.0.51.0
export username=andy@stackrox.com

rm -rf *.tar.gz

echo -n "PASSWORD: "; stty -echo; read password; stty echo; echo
# passwd= # get rid of passwd

#get images - includes roxctl
echo -n " getting image bundle for $version : "
curl -#L -u $username:$password https://install.stackrox.io/$version/image-bundle.tgz -o stackrox_offline_$version.tgz

#get collector packages
echo -n " getting image collector bundle for $version : "
curl -#L -u $username:$password https://install.stackrox.io/$version/image-collector-bundle.tgz -o image-collector-bundle_$version.tgz

echo -n " getting default auth plugin for $version : "
curl -#L -u $username:$password https://install.stackrox.io/authz-plugin/default-authz-plugin-1.0-src.zip -o default-authz-plugin-1.0-src.zip

#get scanner db
echo -n " getting vuln database : "
curl -#LO -u $username:$password -L https://install.stackrox.io/scanner/scanner-vuln-updates.zip

#compressing
cd ..; tar --exclude=.DS_Store --exclude=all_the_things_* -zcvf stackrox_offline/all_the_things_$version.tar.gz stackrox_offline; cd stackrox_offline

# get the roxctl
curl -#L -u $username:$password -L https://install.stackrox.io/3.0.50.1/bin/Linux/roxctl -o roxctl

#rsync
rsync -avP all_the_things_$version.tar.gz new:~andyc/html/rox/
rsync -avP roxctl new:~andyc/html/rox/

#cleanup
rm -rf *.tgz *.zip *.tar.gz roxctl
