# StackRox Offline bits

## Install from the super bundle

### Get all the bits

`wget $(curl -s https://andyc.info/rox/|grep href| grep -v Index|awk -F">" '{print "https://andyc.info/rox/"$2}'|sed 's#</a##g')`

### untar stackrox_all_*

`tar -zxvf stackrox_all_*; cd stackrox_offline`

### install on CentOS

No registry `./offline_install.sh`

With registry `/offline_registry_install.sh`

## Get the offline files directly

Run `getoffline_stackrox.sh`

----

## RHEL versions


```bash 
#login to our reg.
docker login -u andy@stackrox.com stackrox.io
docker login -u andy@stackrox.com collector.stackrox.io

LIST="stackrox.io/main-rhel:3.0.57.2 stackrox.io/scanner-rhel:2.11.2 stackrox.io/scanner-db-rhel:2.11.2 collector.stackrox.io/collector-rhel:3.1.16-latest"

for i in $LIST; do docker pull $i ; done

docker save $LIST -o stackrox-rhel.img
# sneakernet the things. 
```