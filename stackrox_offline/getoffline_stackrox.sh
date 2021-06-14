#!/bin/bash

# vars
export version=3.0.61.0
export username=andy@stackrox.com

rm -rf *.tar.gz

echo -n "PASSWORD: "; stty -echo; read password; stty echo; echo
# passwd= # get rid of passwd

# get images - includes roxctl
echo -n " getting image bundle for $version : "
curl -#L -u $username:$password https://install.stackrox.io/$version/image-bundle.tgz -o stackrox_offline_$version.tgz

# get collector packages
echo -n " getting image collector bundle for $version : "
curl -#L -u $username:$password https://install.stackrox.io/$version/image-collector-bundle.tgz -o image-collector-bundle_$version.tgz

echo -n " getting default auth plugin for $version : "
#curl -#L -u $username:$password https://install.stackrox.io/authz-plugin/default-authz-plugin-1.0-src.zip -o default-authz-plugin-1.0-src.zip

# get scanner db
echo -n " getting vuln database : "
curl -#LO -u $username:$password https://install.stackrox.io/scanner/scanner-vuln-updates.zip

# get kernel modules
echo -n "getting kernel support packages"
curl -#LO -u $username:$password $(curl -sL -u $username:$password https://install.stackrox.io/collector/support-packages/index.html |grep .zip | head -1 | awk -F'"' '{print $4}')

#compressing
cd ..; tar --exclude=.DS_Store --exclude=stackrox_all_* -zcvf stackrox_offline/stackrox_all_$version.tar.gz stackrox_offline; cd stackrox_offline

# get the roxctl
#curl -#L https://mirror.openshift.com/pub/rhacs/assets/$version/bin/Linux/roxctl -o roxctl_Linux_$version

#rsync
rsync -avP stackrox_all_$version.tar.gz new:~andyc/html/rox/
#rsync -avP roxctl_Linux_$version new:~andyc/html/rox/

#cleanup
rm -rf *.tgz *.zip *.tar.gz roxctl_Linux_$version
