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

Or we can use `curl`:

```bash
# default username and password
username=admin
password=Pa22word

# Server
server=graylog.dockr.life

# curl away
curl -k -u $username:$password -X POST http://$server/api/system/inputs \
  -H 'Connection: keep-alive' -H 'Accept: application/json' -H 'X-Requested-With: XMLHttpRequest' -H 'X-Requested-By: XMLHttpRequest' -H 'Content-Type: application/json' \
  -d '{"title":"syslog","type":"org.graylog2.inputs.syslog.tcp.SyslogTCPInput","configuration":{"bind_address":"0.0.0.0","port":514,"recv_buffer_size":1048576,"number_worker_threads":1,"tls_cert_file":"","tls_key_file":"","tls_enable":false,"tls_key_password":"","tls_client_auth":"disabled","tls_client_auth_cert_file":"","tcp_keepalive":false,"use_null_delimiter":false,"max_message_size":2097152,"override_source":null,"force_rdns":false,"allow_override_date":true,"store_full_message":true,"expand_structured_data":false},"global":true,"node":"1195da76-5df0-4122-b701-ed392e0efe95"}'
```

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