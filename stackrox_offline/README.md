# StackRox Offline bits

## Install from the super bundle

### Get all the bits

`wget $(curl -s https://andyc.info/rox/|grep href| grep -v Index|awk -F">" '{print "https://andyc.info/rox/"$2}'|sed 's#</a##g')`

### untar stackrox_all_*

`tar -zxvf stackrox_all_*; cd stackrox_offline`

### install on CentOS

No registry `./offline_install.sh`

with registry `/offline_registry_install.sh`

## Get the offline files directly

Run `getoffline_stackrox.sh`
