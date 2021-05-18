#!/bin/bash
# clemenko@gmail.com
# network simulator yaml

###### no more edits
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
BLUE=$(tput setaf 4)

serverUrl=$1
namespace=$2

# if stackrox_api.token exists
if [ -z $serverUrl ]; then 
 echo "$RED [warn]$NORMAL Please add the server name and namespace to the command."
 echo "  $BLUE Use:$NORMAL $0 <SERVER> <NAMESPACE> "
 exit
fi

# get password. Can modify to hard code it the password. Or use an auth token.
echo -n " -$BLUE StackRox$NORMAL Admin Password for $serverUrl: "; read -s password; echo

# get cluster id - assuming 1 cluster. will need loop for multiple clusters
clusterId=$(curl -sk  -u admin:$password https://$serverUrl/v1/clusters | jq -r .clusters[0].id)
# to be used in the furture.
clusterName=$(curl -sk -u admin:$password https://$serverUrl/v1/clusters/$clusterId | jq -r .cluster.name)

# get network sim
if [ -z $namespace ]; then 
  curl -sk  -u admin:$password "https://$serverUrl/v1/networkpolicies/generate/$clusterId?deleteExisting=ALL&includePorts=true" | jq -r .modification.applyYaml > "$serverUrl"_all_network_policy_$(date +"%m-%d-%y").yaml 
else
  curl -sk  -u admin:$password "https://$serverUrl/v1/networkpolicies/generate/$clusterId?deleteExisting=ALL&query=Namespace%3A$namespace&includePorts=true" | jq -r .modification.applyYaml > "$serverUrl"_"$namespace"_network_policy_$(date +"%m-%d-%y").yaml 
fi