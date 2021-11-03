#!/bin/bash
# clemenko@gmail.com
# import all the policies.

# where are the policies
pol_folder=policies

###### no more edits
set -e

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
BLUE=$(tput setaf 4)

echo -e "----------------------------------------------------------------------------------"
echo -e "StackRox Policy Import Automation Script"
echo " - Inputs: $0 <SERVER NAME>"
echo -e "----------------------------------------------------------------------------------"

serverUrl=$1
if [ -z $serverUrl ]; then echo "$RED [warn]$NORMAL Please add the server name to the command."; echo ""; exit; fi

#read the admin password
echo -n " - StackRox Admin Password for $serverUrl: "; read -s password; echo

echo "  Importing Policies from $pol_folder folder "
  for pol in $(ls $pol_folder/*.json); do 
    echo -n "    $pol_folder/$pol "
    responses=$(curl -sk -X POST -u admin:$password  https://$serverUrl/v1/policies/import -d @$pol)
    if [ "$(echo $responses|grep error\"|wc -l|sed 's/ //g')" == "1" ]; then echo " - $RED Error :$NORMAL $responses $RED [fail]$NORMAL"
    else 
      case "$(echo $responses | jq .responses[].succeeded)" in
        "true") echo -e " - $BLUE Policy Uploaded $GREEN" "[ok]" "$NORMAL\n" ;;
        "false") echo -e " - $BLUE Policy Already Existed $GREEN" "[ok]" "$NORMAL\n" ;;
      esac
    fi
  done
