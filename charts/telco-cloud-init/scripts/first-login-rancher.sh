#!/bin/bash

set -e
set -vx

echo "-- Wait for Rancher deployment to be ready"
attempts=0
until kubectl wait --for condition=Available --timeout 600s --namespace cattle-system deployment rancher; do
sleep 8
((attempts++)) && ((attempts==max_attempts)) && exit -1
done

echo "-- Retrieve randomly generated Rancher bootstrap password"
BOOTSTRAP_PASSWORD=`kubectl -n cattle-system get secret bootstrap-secret -o jsonpath='{.data.bootstrapPassword}' | base64 -d`

echo "-- Login Rancher server and retrieve login token good for 1 minute"
USERNAME=admin
LOGIN_TOKEN=`curl --insecure -s https://rancher.cattle-system.svc.cluster.local/v3-public/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"'$USERNAME'","password":"'$BOOTSTRAP_PASSWORD'","ttl":60000}' | jq -r .token`

echo "-- Create API key good forever and set Rancher server URL"
API_KEY=`curl --insecure -s 'https://rancher.cattle-system.svc.cluster.local/v3/token' -H 'Content-Type: application/json' -H "Authorization: Bearer $LOGIN_TOKEN" --data-binary '{"type":"token","description":"for setting server URL"}' | jq -r .token`
echo "API Key: $API_KEY"
curl --insecure 'https://rancher.cattle-system.svc.cluster.local/v3/settings/server-url' -H 'Content-Type: application/json' -H "Authorization: Bearer $API_KEY" -X PUT --data-binary '{"name":"server-url","value":"https://rancher.sylva"}' | jq .

echo "-- All done"
