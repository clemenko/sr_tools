# Step for installing the open source version of stackrox correctly.

# Go to https://quay.io/repository/stackrox-io/main?tab=tags and check the latet tag's hash. Then see which version has the same hash.
# this is due to there not being a opensource version of roxctl.
export rox_version=3.69.x-418-gc3c3117695

# create the default admin password for logging in.
export password=Pa22word

# get roxctl for your machine
# docs : https://docs.openshift.com/acs/3.68/installing/install-quick-roxctl.html#installing-roxctl-cli
# for Mac
curl -#L https://mirror.openshift.com/pub/rhacs/assets/latest/bin/Darwin/roxctl -o /usr/local/bin/roxctl
chmod +x /usr/local/bin/roxctl

# create the install yamls
# please read the docs about the interactive installer : https://docs.openshift.com/acs/3.68/installing/install-quick-roxctl.html#using-the-interactive-installer_install-quick-roxctl
# Here we are using a PVC from Longhorn and exposing with NodePort. You can apply an ingress to the central pod later.
roxctl central generate k8s pvc --storage-class longhorn --size 10 --enable-telemetry=false --lb-type np --password $password  --main-image quay.io/stackrox-io/main:$rox_version --scanner-db-image quay.io/stackrox-io/scanner-db:$rox_version --scanner-image quay.io/stackrox-io/scanner:$rox_version

# create namespace and install central and scanner
kubectl create ns stackrox
kubectl apply -R -f central-bundle/central/
kubectl apply -R -f central-bundle/scanner/

# validate the ports for the cluster. 
# wait for central to become active.
server=$(kubectl get nodes -o json | jq -r '.items[0].status.addresses[] | select( .type=="InternalIP" ) | .address ')
rox_port=$(kubectl -n stackrox get svc central-loadbalancer |grep Node|awk '{print $5}'|sed -e 's/443://g' -e 's#/TCP##g')

# create a sensor "cluster" using the ports and the admin password.
roxctl sensor generate k8s -e $server:$rox_port --name k3s --central central.stackrox:443 --insecure-skip-tls-verify --collection-method ebpf --admission-controller-listen-on-updates --admission-controller-listen-on-creates -p $password --main-image-repository quay.io/stackrox-io/main:$rox_version --collector-image-repository quay.io/stackrox-io/collector

# deploy the sensor/collectors
kubectl apply -R -f sensor-k3s/

# Now add an ingress and profit...
# for example I use traefik
kubectl apply -f https://raw.githubusercontent.com/clemenko/k8s_yaml/master/stackrox_traefik_crd.yml

# bonus - add an api token for roxctl
# change the $URL to your ingress or ip:nodeport
curl -sk -X POST -u admin:$password https://$URL/v1/apitokens/generate -d '{"name":"admin","role":null,"roles":["Admin"]}'| jq -r .token > ROX_API_TOKEN
