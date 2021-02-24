# Splunk

## Deploy Splunk

This deployment assumes you are using [Traefik](traefik.io).

### Deploy

```bash
# this is going to change the domain for the IngressRoute object.
curl -s https://raw.githubusercontent.com/clemenko/k8s_yaml/master/splunk.yml | sed 's/dockr.life/YOURDOMAIN.com/g' | kubectl apply -f -
```

### Add HTTP Event Collector (HEC)

Log in to `splunk.dockr.life` or your ingress version with `admin` and `Pa22word`.

Now we need add the HTTP Event Collector (HEC). 

- Navigate to `Settings` --> `Data inputs`.
- Click `HTTP Event Collector` --> `New Token`.
  - `Name` : "Stackrox" --> Click `Next`
  - Click `Review`.
  - Click `Submit`.
  - Get the `Token Value`, we will need it later.

## Integrate StackRox

### Create Integration

- Navigate to `Platform Configuration` --> `Integrations`.
- Scroll down and click on "Splunk".
- Click `New Integration`.
  - `Integration Name` : "Splunk"
  - `HTTP Event Collector URL` : https://splunk.splunk:8088
  - `HTTP Event Collector Token` : <TOKEN_VALUE_FROM_SPLUNK>
  - Check `Disable TLS Certificate Validation (Insecure)`
  - UnCheck `Derived Source Type (Instead Of Using _json)`
  - Click `Create`

### Enable Notifications

- Navigate to `Platform Configuration` --> `System Policies`
- Select the Policies for notifications.
  - Click `Actions` --> `Enable Notification`

### to test

```bash
# test from within the cluster. Get the token from the HEC. 
curl -k https://splunk.splunk:8088/services/collector/event -H "Authorization: Splunk e1610a4c-dd8a-48ef-a663-74bb7a811c33" -d '{"event": "Hello, from curl..."}'
```
