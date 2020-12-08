# Graylog Config for Stackrox

## Deploy Graylog

From : [Graylog](https://www.graylog.org/)

Assumptions:

* Running Kubernetes
* Will error without [Traefik](https://traefik.io/)
* Stackrox is up and running
* CLI access

We are going to deploy with https://github.com/clemenko/k8s_yaml/blob/master/graylog.yaml.

```bash
# without traefik you will get an error for `IngressRoute` you can ignore this.
kubectl apply -f https://raw.githubusercontent.com/clemenko/k8s_yaml/master/graylog.yaml
```

### GUI time

* The default username is `admin`.
* The default password is `Pa22word`.

We need to create the `input` from `System / Input` --> `Inputs`. Select `Syslog TCP` and click `Launch new Input`.

Within the Input window select `Global`, give it a name and save. Do not change the bind address or port.

Done with Graylog...

## Configure StackRox

From the StackRox gui, goto `Platform Configuration` --> `Integrations`. Scroll down to and click on `Syslog`. Click the plus in the upper right. Add a name. Leave the formate `CEF`. Leave the log facility as local0. Set the receiver host to `graylog.graylog`. Set the receiver port to `514`. Now Save.

Thats it.

## Testing?

From an alpine container withing the cluster.

```bash
# add logger to the container
apk -U add util-linux

# test logger

logger -n graylog.graylog -P 514 -T "hello from the outside"
```