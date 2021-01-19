#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get install -y dnsutils 

export NUM=$(hostname| sed -e "s/student//" -e "s/a//")
export ipa=$(dig +short student"$NUM"a.stackrox.live)
export ipb=$(dig +short student"$NUM"b.stackrox.live) 
export ipc=$(dig +short student"$NUM"c.stackrox.live)

# k3s
k3sup install --ip $ipa --user root --k3s-extra-args "--no-deploy traefik" --cluster
k3sup join --ip $ipb --server-ip $ipa --user root
k3sup join --ip $ipc --server-ip $ipa --user root
sleep 15 

# traefik
kubectl apply -f https://raw.githubusercontent.com/clemenko/k8s_yaml/master/traefik_crd_deployment.yml

# longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'



# ingress
curl -s https://raw.githubusercontent.com/clemenko/k8s_yaml/master/workshop_yamls.yaml | sed "s/\$NUM/$NUM/" | kubectl apply -f -' 