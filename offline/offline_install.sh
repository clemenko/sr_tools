#!/bin/bash

export version=3.0.43.1

#setup selinux
setenforce 0
systemctl disable firewalld
systemctl stop firewalld

#remove redhat garbage
sed -i 's/best=True/best=False/g' /etc/dnf/dnf.conf
yum remove podman -y
yum install epel-release -y
yum install -y yum-utils jq rsync
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce -y
systemctl start docker
systemctl enable docker
yum update -y

#kernel tuning
cat << EOF >> /etc/sysctl.conf
# SWAP settings
vm.swappiness=0
vm.overcommit_memory=1

# Have a larger connection range available
net.ipv4.ip_local_port_range=1024 65000

# Increase max connection
net.core.somaxconn = 10000

# Reuse closed sockets faster
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15

# The maximum number of "backlogged sockets".  Default is 128.
net.core.somaxconn=4096
net.core.netdev_max_backlog=4096

# 16MB per socket - which sounds like a lot,
# but will virtually never consume that much.
net.core.rmem_max=16777216
net.core.wmem_max=16777216

# Various network tunables
net.ipv4.tcp_max_syn_backlog=20480
net.ipv4.tcp_max_tw_buckets=400000
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_wmem=4096 65536 16777216

# ARP cache settings for a highly loaded docker swarm
net.ipv4.neigh.default.gc_thresh1=8096
net.ipv4.neigh.default.gc_thresh2=12288
net.ipv4.neigh.default.gc_thresh3=16384

# ip_forward and tcp keepalive for iptables
net.ipv4.tcp_keepalive_time=600
net.ipv4.ip_forward=1

# needed for host mountpoints with RHEL 7.4
fs.may_detach_mounts=1

# monitor file system events
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
EOF
sysctl -p

#get kubectl
curl -L# https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod 755 /usr/local/bin/kubectl

#password for all the things
export password=Pa22word

#get local ip
export server=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

#setup local registry
docker run -d -p 5000:5000 --restart always --name registry registry
export registry=$server:5000
echo '{ "insecure-registries" : ["'$registry'"] }' > /etc/docker/daemon.json
systemctl restart docker

#install Rancher
docker run -d -p 80:80 -p 443:443 --restart=unless-stopped rancher/rancher

token=$(curl -sk https://$server/v3-public/localProviders/local?action=login -H 'content-type: application/json' -d '{"username":"admin","password":"admin"}'| jq -r .token)

curl -sk https://$server/v3/users?action=changepassword -H 'content-type: application/json' -H "Authorization: Bearer $token" -d '{"currentPassword":"admin","newPassword":"'$password'"}'

api_token=$(curl -sk https://$server/v3/token -H 'content-type: application/json' -H "Authorization: Bearer $token" -d '{"type":"token","description":"automation"}' | jq -r .token)

curl -sk https://$server/v3/settings/server-url -H 'content-type: application/json' -H "Authorization: Bearer $api_token" -X PUT -d '{"name":"server-url","value":"https://'$server'"}'

curl -sk https://$server/v3/settings/telemetry-opt -X PUT -H 'content-type: application/json' -H 'accept: application/json' -H "Authorization: Bearer $api_token" -d '{"value":"out"}'

clusterid=$(curl -sk https://$server/v3/cluster -H 'content-type: application/json' -H "Authorization: Bearer $api_token" -d '{"type":"cluster","nodes":[],"rancherKubernetesEngineConfig":{"ignoreDockerVersion":true},"name":"rancher"}' | jq -r .id )

agent_command=$(curl -sk https://$server/v3/clusterregistrationtoken -H 'content-type: application/json' -H "Authorization: Bearer $api_token" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$clusterid'"}' | jq -r .nodeCommand)

$agent_command --etcd --controlplane --worker

#setup kube
mkdir ~/.kube
curl -sk https://$server/v3/clusters/$clusterid?action=generateKubeconfig -X POST -H 'accept: application/json' -H "Authorization: Bearer $api_token" | jq -r .config > ~/.kube/config

#get roxctl
curl -# -u andy@stackrox.com: -L https://install.stackrox.io/$version/bin/Linux/roxctl -o /usr/local/bin/roxctl
chmod 755 /usr/local/bin/roxctl

#unzip images
tar xzvf stackrox_offline_*
tar xzvf image-collector-bundle_*

#load images
image-bundle/import.sh
image-collector-bundle/import.sh

#generate stackrox install
roxctl central generate k8s none --offline --enable-telemetry=false --lb-type np --main-image $registry/main:$version --scanner-db-image $registry/scanner-db:2.2.7 --scanner-image $registry/scanner:2.2.7 --password $password

#offline magic
sed -i -e '/imagePullSecrets:/d' -e '/- name: stackrox/d' central-bundle/central/00-serviceaccount.yaml
sed -i '32,$d' ./central-bundle/central/scripts/setup.sh

#reduce StackRox requirements
sed -i -e 's/4Gi/2Gi/g' -e 's/8Gi/4Gi/g' ./central-bundle/central/deployment.yaml
sed -i -e 's/4Gi/2Gi/g' -e 's/8Gi/4Gi/g' ./central-bundle/scanner/deployment.yaml

#install
./central-bundle/central/scripts/setup.sh
kubectl apply -R -f central-bundle/central

#get port
rox_port=$(kubectl -n stackrox get svc central-loadbalancer |grep Node|awk '{print $5}'|sed -e 's/443://g' -e 's#/TCP##g')
until [ $(curl -kIs https://$server:$rox_port|head -n1|wc -l) = 1 ]; do echo -n "." ; sleep 2; done

#get sensor bundle
roxctl -e $server:$rox_port sensor generate k8s --name rancher --central central.stackrox:443 --insecure-skip-tls-verify --image $registry/main:3.0.41.0 -p $password 

#kubectl apply -R -f central-bundle/scanner/

sed -i '27,56d' ./sensor-rancher/sensor.sh
sed -i -e "s/collector.stackrox.io/$registry/g" -e "s#stackrox.io/main#$registry/main#g" sensor-rancher/sensor.yaml
sed -i -e '/imagePullSecrets:/d' -e '/- name: stackrox/d' sensor-rancher/sensor.yaml
./sensor-rancher/sensor.sh
