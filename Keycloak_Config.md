# Keycloak Config

This doc is to help deploy [Keycloak](https://www.keycloak.org/) and configure [StackRox](https://stackrox.com).

## Deploy Keycloak

This deployment is designed for use with [Traefik](https://traefik.io/). An `IngressRouteTCP` is included for TLS passthrough to the self signed cert of keycloak

`kubectl apply -f https://raw.githubusercontent.com/clemenko/k8s_yaml/master/keycloak.yml`

Login with username : `admin` and password `Pa22word`.

### Configure Stackrox Realm

Click **Master --> Add realm** and name it `stackrox`.

#### Add Stackrox Client

Once created click **Clients** on the left. Then Click **Create**.

`Client ID` : stackrox

`Protocol` : openid-connect

`Root URL` : ""

Next we need to change the `Access Type` to `confidental`. We also need to set the `Valid Redirect URLs` to `https://stackrox.$DOMAIN_NAME/sso/providers/oidc/callback`. Make sure you change your domain name.

now save.

#### Get Client Secret

Next click the **Credentials** tab to get the secret.

### Create user

Next click the **Users** on the left and **Add User**. This should be obvious. Next click the **Credentials** tab to enter a password. Also make sure `Temporary` is off. And click `Reset Password`

## Configure StackRox

### Add Auth Provider

Navigate to **PLATFORM CONFIGURATION --> ACCESS CONTROL**

Then **Add an Auth Provider --> OpenID Connect**

`Name` : Generic Name, anything will work.

`HTTP POST` : Checked

`Issuer` : https+insecure://keycloak.dockr.life/auth/realms/stackrox/

`Client ID` : stackrox

`Client Secret` : "From the keycloak client credentials page."

Click Save and Test.