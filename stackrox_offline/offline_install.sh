#!/bin/bash

export version=3.0.50.0
export password=Pa22word
export server=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1|head -1)

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
yum install -y https://rpm.rancher.io/k3s-selinux-0.1.1-rc1.el7.noarch.rpm

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
#curl -L# https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
#chmod 755 /usr/local/bin/kubectl

#deploy k3s
mkdir ~/.kube/
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--no-deploy=traefik --docker" INSTALL_K3S_CHANNEL="stable" sh -
rsync -avP /etc/rancher/k3s/k3s.yaml ~/.kube/config

#uncompress more stuff
tar -zxvf stackrox_offline_$version.tgz
tar -zxvf image-collector-bundle_$version.tgz

#move roxctl
rsync -avP image-bundle/bin/linux/roxctl /usr/local/bin/
chmod 755 /usr/local/bin/roxctl

#load images
for i in $(ls image-bundle/*.img); do docker load -i $i; done
for i in $(ls image-collector-bundle/*.img); do docker load -i $i; done

#generate stackrox install
roxctl central generate k8s none --offline --enable-telemetry=false --lb-type np --password $password

#reduce StackRox requirements
sed -i -e 's/4Gi/2Gi/g' -e 's/8Gi/4Gi/g' ./central-bundle/central/01-central-12-deployment.yaml 
sed -i -e 's/4Gi/2Gi/g' -e 's/8Gi/4Gi/g' -e 's/replicas: 3/replicas: 1/g' ./central-bundle/scanner/02-scanner-06-deployment.yaml
sed -i -e 's/minReplicas: 2/minReplicas: 1/g' central-bundle/scanner/02-scanner-08-hpa.yaml

#install
kubectl create ns stackrox
kubectl apply -R -f central-bundle/central
kubectl apply -R -f central-bundle/scanner

#get port
rox_port=$(kubectl -n stackrox get svc central-loadbalancer |grep Node|awk '{print $5}'|sed -e 's/443://g' -e 's#/TCP##g')
until [ $(curl -kIs https://$server:$rox_port|head -n1|wc -l) = 1 ]; do echo -n "." ; sleep 2; done

#get sensor bundle
roxctl -e $server:$rox_port sensor generate k8s --name k3s --central central.stackrox:443 --insecure-skip-tls-verify -p $password 

#slight mod for pre-loaded images
sed -i -e "s/imagePullPolicy: Always/imagePullPolicy: IfNotPresent/g" sensor-k3s/sensor.yaml
kubectl apply -R -f sensor-k3s/

#update vulns database
roxctl scanner upload-db -e $server:$rox_port --scanner-db-file=scanner-vuln-updates.zip --insecure-skip-tls-verify -p $password
