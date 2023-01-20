#!/bin/bash
# this uses the RANCHER_EXTERNAL_URL as an environment variable (e.g. RANCHER_EXTERNAL_URL=https://rancher.sylva)

set -e
set -o pipefail

echo "-- Wait for Rancher deployment to be ready"
kubectl wait --for condition=Available --timeout 600s --namespace cattle-system deployment rancher
FIRST_CREATED_POD=`kubectl -n cattle-system get pod -l app=rancher --sort-by=.metadata.creationTimestamp -o=jsonpath='{.items[0].metadata.name}'`
kubectl wait --for condition=Ready --timeout 600s --namespace cattle-system pod $FIRST_CREATED_POD

echo "-- Retrieve randomly generated Rancher bootstrap password"
BOOTSTRAP_PASSWORD=`kubectl -n cattle-system get secret bootstrap-secret -o jsonpath='{.data.bootstrapPassword}' | base64 -d`

echo "-- Login Rancher server and retrieve login token good for 1 minute"
USERNAME=admin
LOGIN_TOKEN=`curl --insecure -s https://rancher.cattle-system.svc.cluster.local/v3-public/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"'$USERNAME'","password":"'$BOOTSTRAP_PASSWORD'","ttl":60000}' | jq -r .token`
echo "Login token: $LOGIN_TOKEN"

if [[ -z $LOGIN_TOKEN ]]; then
    echo "LOGIN_TOKEN is set to the empty string, will try again"
    exit 1
fi

echo "-- Create API key good forever and set Rancher server URL"
API_KEY=`curl --insecure -s 'https://rancher.cattle-system.svc.cluster.local/v3/token' -H 'Content-Type: application/json' -H "Authorization: Bearer $LOGIN_TOKEN" --data-binary '{"type":"token","description":"for setting server URL"}' | jq -r .token`
echo "API key: $API_KEY"

if [[ -z $API_KEY ]]; then
    echo "API_KEY is set to the empty string, will try again"
    exit 1
fi

curl --insecure 'https://rancher.cattle-system.svc.cluster.local/v3/settings/server-url' -H 'Content-Type: application/json' -H "Authorization: Bearer $API_KEY" -X PUT --data-binary '{"name":"server-url","value":"'$RANCHER_EXTERNAL_URL'"}' | jq .

echo "-- All done"
