# Keycloak Config

This doc is to help deploy [Keycloak](https://www.keycloak.org/) and configure [StackRox](https://stackrox.com).

## Deploy Keycloak

This deployment is designed for use with [Traefik](https://traefik.io/). An `IngressRouteTCP` is included for TLS passthrough to the self signed cert of keycloak

`kubectl apply -f https://raw.githubusercontent.com/clemenko/k8s_yaml/master/keycloak.yml`

Login with username : `admin` and password `Pa22word`.

### Configure Stackrox Realm in Keycloak

Click **Master --> Add realm** and name it `stackrox`.

### Create user

Next click the **Users** on the left and **Add User**. This should be obvious. Next click the **Credentials** tab to enter a password. Also make sure `Temporary` is off. And click `Reset Password`

---

## OIDC Configuration

### Add Stackrox OIDC Client - Keycloak

Once created click **Clients** on the left. Then Click **Create**.

`Client ID` : stackrox

`Protocol` : openid-connect

`Root URL` : ""

Next we need to change the `Access Type` to `confidental`. We also need to set the `Valid Redirect URLs` to `https://stackrox.dockr.life/sso/providers/oidc/callback`. Make sure you change your domain name.

now save.

#### Get Client Secret

Next click the **Credentials** tab to get the secret.

### Configure StackRox OpenID

#### Add Auth Provider

Navigate to **PLATFORM CONFIGURATION --> ACCESS CONTROL**

Then **Add an Auth Provider --> OpenID Connect**

`Name` : Generic Name, anything will work.

`HTTP POST` : Checked

`Issuer` : https+insecure://keycloak.dockr.life/auth/realms/stackrox

`Client ID` : stackrox

`Client Secret` : "From the keycloak client credentials page."

Click Save and Test.

#### Add Rules as needed - OIDC

## OIDC Automation

```bash
# URLs 
export KEY_URL=keycloak.dockr.life
export ROX_URL=stackrox.dockr.life
export ROX_PASSWORD=Pa22word

# KEYCLOAK
# get auth token - notice keycloak's password 
export key_token=$(curl -sk -X POST https://$KEY_URL/auth/realms/master/protocol/openid-connect/token -d 'client_id=admin-cli&username=admin&password=Pa22word&credentialId=&grant_type=password' | jq -r .access_token)

# add realm
curl -sk -X POST https://$KEY_URL/auth/admin/realms -H "authorization: Bearer $key_token" -H 'accept: application/json, text/plain, */*' -H 'content-type: application/json;charset=UTF-8' -d '{"enabled":true,"id":"stackrox","realm":"stackrox"}'

# add client
curl -sk -X POST https://$KEY_URL/auth/admin/realms/stackrox/clients -H "authorization: Bearer $key_token" -H 'accept: application/json, text/plain, */*' -H 'content-type: application/json;charset=UTF-8' -d '{"enabled":true,"attributes":{},"redirectUris":[],"clientId":"stackrox","protocol":"openid-connect","publicClient": false,"redirectUris":["https://'$ROX_URL'/sso/providers/oidc/callback"]}'

# get client id
export client_id=$(curl -sk  https://$KEY_URL/auth/admin/realms/stackrox/clients/ -H "authorization: Bearer $key_token"  | jq -r '.[] | select(.clientId=="stackrox") | .id')

# get client_secret
export client_secret=$(curl -sk  https://$KEY_URL/auth/admin/realms/stackrox/clients/$client_id/client-secret -H "authorization: Bearer $key_token" | jq -r .value)

# STACKROX
# config stackrox
export auth_id=$(curl -sk -X POST -u admin:$ROX_PASSWORD https://$ROX_URL/v1/authProviders -d '{"type":"oidc","uiEndpoint":"'$ROX_URL'","enabled":true,"config":{"mode":"post","do_not_use_client_secret":"false","client_secret":"'$client_secret'","issuer":"https+insecure://'$KEY_URL'/auth/realms/stackrox","client_id":"stackrox"},"name":"stackrox"}' | jq -r .id)

# change default to Analyst
curl -sk -X POST -u admin:$ROX_PASSWORD https://$ROX_URL/v1/groups -d '{"props":{"authProviderId":"'$auth_id'"},"roleName":"Analyst"}'
```

---

## SAML2 Configuration

### Add Stackrox SAML2 Client - Keycloak

Once created click **Clients** on the left. Then Click **Create**.

`Client ID` : stackrox

`Protocol` : saml

`Root URL` : ""

Next we need to validate the following settings.

`Client ID`: stackrox

`Base URL`: https://stackrox.dockr.life

`Client Protocol`: saml

`Include AuthnStatement`: ON

`Force POST Binding`: ON

`Name ID Format`: username

`Valid Redirect URIs`: https://stackrox.dockr.life/*

`IDP Initiated SSO URL Name`: stackrox

Under Fine Grain SAML Endpoint Configuration

`Assertion Consumer Service Redirect Binding URL`: https://stackrox.dockr.life/sso/providers/saml/acs

### in Stackrox

`Integration Name`: Keycloak

`ServiceProvider Issuer`: https://keycloak.dockr.life

`Option 2: Static Configuration`

`idP Issuer`: https://keycloak.dockr.life/auth/realms/stackrox

`IdP SSO URL`: https://keycloak.dockr.life/auth/realms/stackrox/protocol/saml/clients/stackrox

`Name/ID Format`: urn:oasis:names:tc:SAML:2.0:nameid-format:persistent

`IdP Certificate (PEM)`:
(can be retrieved from https://keycloak.dockr.life/auth/realms/stackrox/protocol/saml/descriptor, you have to add this part below:)

```bash
# paste in the Realm Cert
export CERT=

# parse 
echo "-----BEGIN CERTIFICATE-----"; echo $CERT | sed -e 's/.\{64\}/&\n/g'; echo "-----END CERTIFICATE-----"
```

#### Add Rules as needed - SAML
