#!/bin/bash

# k3s
k3sup install --ip $ipa --user root --k3s-extra-args "--no-deploy traefik" --cluster
k3sup join --ip $ipb --server-ip $ipa --user root
k3sup join --ip $ipc --server-ip $ipa --user root
sleep 15 
sed -i "s/127.0.0.1/$ipa/" /etc/rancher/k3s/k3s.yaml

# traefik
kubectl apply -f https://raw.githubusercontent.com/clemenko/k8s_yaml/master/traefik_crd_deployment.yml

# longhorn
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
sleep 5

#wait for longhorn to initiaize
until [ $(kubectl get pod -n longhorn-system | grep -v 'Running\|NAME' | wc -l) = 0 ] && [ "$(kubectl get pod -n longhorn-system | wc -l)" -gt 20 ] ; do sleep 2; done

kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

# code
curl -s https://raw.githubusercontent.com/clemenko/k8s_yaml/master/workshop-code-server.yml | sed 's/dockr.life/'$NUM'.stackrox.live/g' | kubectl  apply -f -

# ingress
curl -s https://raw.githubusercontent.com/clemenko/k8s_yaml/master/workshop_yamls.yaml | sed "s/\$NUM/$NUM/" | kubectl apply -f -