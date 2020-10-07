# offline & k3s

## deploy local registry

make sure you use the front facing ip

```bash
docker run -d -p 5000:5000 --restart always --name registry registry
export registry=10.211.55.30:5000
echo '{ "insecure-registries" : ["'$registry'"] }' > /etc/docker/daemon.json
systemctl restart docker
```

## import image-bundle

point to the local registry
```bash
./import.sh
```

## k3s with Docker

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--no-deploy=traefik --docker" sh -
```

## k3s with containerd

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--no-deploy=traefik" sh -
cat << EOF >> /etc/rancher/k3s/registries.yaml
mirrors:
  "$registry":
    endpoint:
      - "http://$registry"
EOF
systemctl restart k3s
```

## install stackrox

```bash
export password=Pa22word
export registry=10.211.55.30:5000
roxctl central generate k8s none --offline --enable-telemetry=false --lb-type np --main-image $registry/main:3.0.39.3 --scanner-db-image $registry/scanner-db:2.2.1 --scanner-image $registry/scanner:2.2.1 --password $password

sed -i -e '/imagePullSecrets:/d' -e '/- name: stackrox/d' central-bundle/central/00-serviceaccount.yaml
sed -i '32,$d' ./central-bundle/central/scripts/setup.sh

./central-bundle/central/scripts/setup.sh
kubectl apply -R -f central-bundle/central
```

## remove k3s

```bash
/usr/local/bin/k3s-uninstall.sh
```
