#!/bin/bash

# this script it intended for centos on an airgapped network. 
# assumptions are made that some things are available.
# this script also assumes all the images are loaded to the servers

export version=3.0.58.1
export password=Pa22word
export server=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1|head -1)

# setup selinux
setenforce 0
systemctl disable firewalld
systemctl stop firewalld

# remove redhat garbage
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

# get kubectl
curl -L# https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod 755 /usr/local/bin/kubectl

# deploy k3s
mkdir ~/.kube/
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--no-deploy=traefik --docker" INSTALL_K3S_CHANNEL="stable" sh -
rsync -avP /etc/rancher/k3s/k3s.yaml ~/.kube/config

# get the files onto the server......
# sneaker net or
wget $(curl -s https://andyc.info/rox/|grep href|grep -v Index|grep -v Linux|awk -F">" '{print "https://andyc.info/rox/"$2}'|sed 's#</a##g')

# untar the beast
tar -zxvf stackrox_all_*; cd stackrox_offline

# uncompress more stuff
tar -zxvf stackrox_offline_$version.tgz
tar -zxvf image-collector-bundle_$version.tgz

#move roxctl
rsync -avP image-bundle/bin/linux/roxctl /usr/local/bin/
chmod 755 /usr/local/bin/roxctl

# load images to registry
# PLEASE REMEMBER THE REGISTRY URL
# Assuming SERVER/stackrox/
image-bundle/import.sh
image-collector-bundle/import.sh

export registry=<CHANGE ME>

# generate stackrox install
roxctl central generate k8s none --offline --enable-telemetry=false --lb-type np --password $password --main-image $registry/stackrox/main:3.0.52.1 --scanner-db-image $registry/stackrox/scanner-db:2.7.1 --scanner-image $registry/stackrox/scanner:2.7.1 --slim-collector=false --admission-controller-listen-on-updates --create-admission-controller

# reduce StackRox requirements
sed -i -e 's/4Gi/2Gi/g' -e 's/8Gi/4Gi/g' ./central-bundle/central/01-central-12-deployment.yaml 
sed -i -e 's/4Gi/2Gi/g' -e 's/8Gi/4Gi/g' -e 's/replicas: 3/replicas: 1/g' ./central-bundle/scanner/02-scanner-06-deployment.yaml
sed -i -e 's/minReplicas: 2/minReplicas: 1/g' central-bundle/scanner/02-scanner-08-hpa.yaml

# how do the nodes authenticate to the registry?
###############################################################################################
# if you have your nodes authenticate for you start here
# if not skip the `sed` statements

# remove the auth assumptions
sed -i -e '25,$d' central-bundle/central/scripts/setup.sh 
sed -i -e '9,$d' central-bundle/scanner/scripts/setup.sh

# proceed with the `imagePullSecrets` path

###############################################################################################
# if you need imagePullSecrets then start here
# run the setup and enter the registry creds

#deploy
./central-bundle/central/scripts/setup.sh

# kube all the things
kubectl apply -R -f central-bundle/central

# install scanner
./central-bundle/scanner/scripts/setup.sh
kubectl apply -R -f central-bundle/scanner

###############################################################################################

# get port
rox_port=$(kubectl -n stackrox get svc central-loadbalancer |grep Node|awk '{print $5}'|sed -e 's/443://g' -e 's#/TCP##g')
until [ $(curl -kIs https://$server:$rox_port|head -n1|wc -l) = 1 ]; do echo -n "." ; sleep 2; done

# get sensor bundle
roxctl -e $server:$rox_port sensor generate k8s --name k3s --central central.stackrox:443 --insecure-skip-tls-verify -p $password --collection-method kernel --main-image $registry/stackrox/main:$version

# how do the nodes authenticate to the registry?
###############################################################################################
# if you have your nodes authenticate for you start here
# if not skip the `sed` statement
sed -i -e '25,57d' sensor-k3s/sensor.sh 

# apply the sensor bundle
kubectl apply -R -f sensor-k3s/

# update vulns database
roxctl scanner upload-db -e $server:$rox_port --scanner-db-file=scanner-vuln-updates.zip --insecure-skip-tls-verify -p $password

# update the the kernel modules
roxctl collector support-packages upload $server:$rox_port support-pkg-b6745d-latest.zip
