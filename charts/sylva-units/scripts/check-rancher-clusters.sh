#!/bin/bash

set -e
set -o pipefail

echo "-- Retrieve randomly generated Rancher bootstrap password"
BOOTSTRAP_PASSWORD=`kubectl -n cattle-system get secret bootstrap-secret -o jsonpath='{.data.bootstrapPassword}' | base64 -d`

echo "-- Login Rancher server and retrieve login token good for 10 minute"
USERNAME=admin
LOGIN_TOKEN=`curl --insecure -s https://rancher.cattle-system.svc.cluster.local/v3-public/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"'$USERNAME'","password":"'$BOOTSTRAP_PASSWORD'","ttl":600000}' | jq -r .token`

if [ -z "${LOGIN_TOKEN}" ] || [ "${LOGIN_TOKEN}" = "null" ] ; then
    echo "LOGIN_TOKEN is set to the empty string, will try again"
    exit 1
fi

echo "-- Show the clusters known to Rancher"
curl --insecure -s https://rancher.cattle-system.svc.cluster.local/v3/clusters/  -H "Authorization: Bearer $LOGIN_TOKEN" | jq '.data[]  | .name, .labels, .conditions[6], .conditions[-2]'

echo "-- All done"
