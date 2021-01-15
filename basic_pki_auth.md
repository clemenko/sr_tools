# StackRox Auth

## basic

```bash
# preserve the current admin password
kubectl exec -it $(kubectl get pod -n stackrox|grep central|awk '{print $1}') -n stackrox -- /bin/cat /run/secrets/stackrox.io/htpasswd/htpasswd > htpasswd

# add user to the new file aka change user2 to the desired username
htpasswd -B htpasswd user2

# delete the old secret 
kubectl -n stackrox delete secret central-htpasswd

# add the new secret file
kubectl -n stackrox create secret generic central-htpasswd --from-file=htpasswd=htpasswd
```

Please be advised that it can take a minute for the new htpasswd to be read.

## pki

```bash
roxctl -e <hostname>:<port-number> central userpki create -c <ca-certificate-file> -r <default-role-name> <provider-name> --insecure-skip-tls-verify -p $password
```