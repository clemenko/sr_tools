#!/bin/bash
# clemenko@gmail.com

set -e

if [[ -z "${ROX_ENDPOINT}" ]]; then
 echo >&2 "ROX_ENDPOINT must be set. ie : export ROX_ENDPOINT=stackrox.dockr.life:443"
 exit 1
fi

if [[ -z "${ROX_API_TOKEN}" ]]; then
 echo >&2 "ROX_API_TOKEN must be set"
 # export ROX_API_TOKEN=$(curl -sk -X POST -u admin:Pa22word https://stackrox.dockr.life/v1/apitokens/generate -d '{"name":"Report","role":null,"roles":["Analyst"]}'| jq -r .token )
 exit 1
fi

if [[ -z "$1" ]]; then
 echo >&2 "usage: $0 <namespace>"
 exit 1
fi

export namespace=$1

output_file="$namespace"_Results_$(date +"%m-%d-%y").csv
echo '"Namespace","Deployment","Image","CVE","CVSS","Fixable"' > "${output_file}"

function curl_central() {
 curl -sk -H "Authorization: Bearer ${ROX_API_TOKEN}" "https://${ROX_ENDPOINT}/$1"
}

# Collect all deployments
deploy_count=0
image_count=0
offset=0
limit=100
echo -n " Starting Report "
while true; do
  res=$(curl_central "v1/deployments?pagination.limit=${limit}&pagination.offset=${offset}" | jq ['.deployments[] |select(.namespace=="'$namespace'")'])

  # If no results, then exist
  if [[ "$(echo "${res}" | jq length)" == "0" ]]; then break; fi

  # Iterate over all deployments and get the full deployment
  for deployment_id in $(echo "${res}" | jq -r .[].id); do
    deployment_res="$(curl_central "v1/deployments/${deployment_id}")"
    export deployment_name="$(echo "${deployment_res}" | jq -rc .name)"
    deploy_count=$((deploy_count+1))
    # Iterate over all images within the deployment and render the CSV Lines
    for image_id in $(echo "${deployment_res}" | jq -r .containers[].image.id); do
      if [[ "${image_id}" != "" ]]; then
        echo -n "."
        image_res="$(curl_central "v1/images/${image_id}" | jq -rc)"
        export image_name="$(echo "${image_res}" | jq -rc .name.fullName)"
        image_count=$((image_count+1))

        # Format the CSV correctly
        echo "${image_res}" | jq -r '.scan?.components[]?.vulns[]? | {nameSpace: env.namespace, deploymentName: env.deployment_name, imageName: env.image_name, cve: .cve, cvss: .cvss, fixedBy: .fixedBy } | [ .nameSpace, .deploymentName, .imageName, .cve, .cvss, .fixedBy != null ] | @csv' >> "${output_file}" 
      fi
    done
  done
  echo ""
  offset=$(( offset + limit ))
  echo "$(date): Processed Namespace: $namespace - $deploy_count deployments and $image_count images."
done