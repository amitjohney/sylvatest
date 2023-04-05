#!/bin/bash

set -e
set -o pipefail

REALM="sylva"
RANCHER_INTERNAL_URL="https://rancher.cattle-system.svc.cluster.local" #use for internal call to rancher api
RANCHER_EXTERNAL_URL="https://rancher.sylva" #use for EXTERNAL call to rancher api
KEYCLOAK_EXTERNAL_URL="https://keycloak.sylva" #use for EXTERNAL communication between keycloak and rancher
KEYCLOAKOIDC_CLIENT_ID="sylva-admin"
KEYCLOAKOIDC_AUTH_ENDPOINT="$KEYCLOAK_EXTERNAL_URL/realms/$REALM/protocol/openid-connect/auth"
KEYCLOAKOIDC_ISSUER="$KEYCLOAK_EXTERNAL_URL/realms/$REALM"
KEYCLOAKOIDC_RANCHER_URL="$RANCHER_EXTERNAL_URL/verify-auth"
KEYCLOAKOIDC_ACCESSMODE="unrestricted"


echo "-- Retrieve randomly generated Rancher bootstrap password"
BOOTSTRAP_PASSWORD=`kubectl -n cattle-system get secret bootstrap-secret -o jsonpath='{.data.bootstrapPassword}' | base64 -d`

echo "-- Login Rancher server and retrieve login token good for 1 minute"
USERNAME=admin
ACCESS_TOKEN=`curl --insecure -s $RANCHER_INTERNAL_URL/v3-public/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"'$USERNAME'","password":"'$BOOTSTRAP_PASSWORD'","ttl":60000}'  | jq -r .token`


echo "-- add  KEYCLOAK authentication provider into Rancher server"
curl -k --insecure -u $ACCESS_TOKEN  \
        -X PUT \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{    "accessMode": "'$KEYCLOAKOIDC_ACCESSMODE'", 
                 "allowedPrincipalIds": ["keycloakoidc_user://'$KEYCLOAKOIDC_CLIENT_ID'","keycloakoidc_group://infra-admins"],
                 "authEndpoint": "'$KEYCLOAKOIDC_AUTH_ENDPOINT'",  
                 "clientId": "'$KEYCLOAKOIDC_CLIENT_ID'", 
                 "clientSecret": "'$RANCHER_CLIENT_SECRET'",  
                 "creatorId": null,    "enabled": true,   
                 "groupSearchEnabled": null,   
                 "issuer": "'$KEYCLOAKOIDC_ISSUER'",   
                 "name": "keycloakoidc",   
                 "ownerReferences": [ ],   
                 "rancherUrl": "'$KEYCLOAKOIDC_RANCHER_URL'",   
                 "scope": "openid profile email",    "type": "keyCloakOIDCConfig"}' \
       $RANCHER_INTERNAL_URL/v3/keyCloakOIDCConfigs/keycloakoidc?action=testAndApply > /tmp/result.txt

