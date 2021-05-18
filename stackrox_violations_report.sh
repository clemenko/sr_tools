#!/bin/bash
# clemenko@gmail.com

# script for pulling violations by namespace. 

# output formats are json or csv
# ONLY JSON right now. Plans for possibly CSV
output_format=json

###### no more edits
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

function setup () {  # set up token
    
    echo -e "Creating the API token. Admin password required. " 
    #read the admin password
    echo -n " - StackRox Admin Password for $serverUrl: "; read -s password; echo

    # create token with  role
    curl -sk -X POST -u admin:$password https://$serverUrl/v1/apitokens/generate -d '{"name":"violations","role":null,"roles":["Analyst"]}'| jq -r .token > "$serverUrl".token

    echo -e "\n----------------------------------------------------------------------------------"
}

echo -e "\n StackRox Complaince Automation Script"
echo " - Inputs: ./stackrox_violations_report.sh <SERVER NAME> <NAMESPACE>"
echo " - Outputs: <SERVERNAME>_<CLUSTERNAME>_<STANDARD>_Results_$(date +"%m-%d-%y").$output_format"
echo -e "----------------------------------------------------------------------------------\n"

serverUrl=$1
if [ -z $serverUrl ]; then echo "$RED [warn]$NORMAL Please add the server name to the command."; echo ""; exit; fi

namespace=$2
if [ -z $namespace ]; then echo "$RED [warn]$NORMAL Please add the namespace to the command."; echo ""; exit; fi

# if stackrox_api.token exists
if [ ! -f "$serverUrl".token ]; then setup; fi

# get api
export token=$(cat "$serverUrl".token)

echo -n "Getting Violations from $serverUrl for $namespace"

if [[ "$output_format" = "json" ]]; then
  # get results in json
#  curl -sk -H "Authorization: Bearer $token" https://$serverUrl/v1/alerts |jq '.alerts[]? | select(.deployment.namespace=="'$namespace'")' | jq . > "$serverUrl"_"$namespace"_Violations_$(date +"%m-%d-%y").json
  curl -sk -H "Authorization: Bearer $token" https://$serverUrl/v1/alerts?query=Namespace%3A$namespace  | jq . > "$serverUrl"_"$namespace"_Violations_$(date +"%m-%d-%y").json
fi

echo -e "$GREEN" "[ok]" "$NORMAL\n"
