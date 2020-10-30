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

## Configure StackRox OpenID

### Add Auth Provider

Navigate to **PLATFORM CONFIGURATION --> ACCESS CONTROL**

Then **Add an Auth Provider --> OpenID Connect**

`Name` : Generic Name, anything will work.

`HTTP POST` : Checked

`Issuer` : https+insecure://keycloak.dockr.life/auth/realms/stackrox/

`Client ID` : stackrox

`Client Secret` : "From the keycloak client credentials page."

Click Save and Test.

## Notes for Saml2

### in Stackrox:

Integration Name: Keycloak

ServiceProvider Issuer: https://keycloak.url

idP Issuer: https://keycloak.url/auth/realms/[yourrealm]

IdP SSO URL: https://keycloak.url/auth/realms/[yourrealm]/protocol/saml/clients/[keycloak client name]

Name/ID Format: urn:oasis:names:tc:SAML:2.0:nameid-format:persistent

IdP Certificate (PEM): 
(can be retrieved from https://keycloak.url/auth/realms/[yourrealm]/protocol/saml/descriptor, you have to add this part below:)

-----BEGIN CERTIFICATE-----

-----END CERTIFICATE-----

### Keycloak Client:

Client ID: https://[stackrox url]/login

Base URL: [stackrox url]

Name: keycloak

Client Protocol: saml

Include AuthnStatement: ON

Sign Assertions: ON

Force POST Binding: ON

Name ID Format: username

Valid Redirect URIs: https://[stackrox url]/*

IDP Initiated SSO URL Name: stackrox

Under Fine Grain SAML Endpoint Configuration

Assertion COnsumer Service Redirect Binding URL: https://[stackrox url]/sso/providers/saml/acs
