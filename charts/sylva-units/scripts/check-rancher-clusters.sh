#!/bin/bash
# this uses the CLUSTER_NAME as an environment variable (e.g. CLUSTER_NAME="first-workload-cluster")

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

echo "-- Get kubeconfig URL for the '${CLUSTER_NAME}'"
KUBECONFIG_URL=`curl --insecure -s https://rancher.cattle-system.svc.cluster.local/v3/clusters/  -H "Authorization: Bearer $LOGIN_TOKEN" | jq '.data[] | select (.name=="'${CLUSTER_NAME}'-capi") | .actions.generateKubeconfig' | tr -d '"'`
echo $KUBECONFIG_URL
curl --insecure -s -X POST $KUBECONFIG_URL  -H "Authorization: Bearer $LOGIN_TOKEN" | jq ".config" > /tmp/kubeconfig

echo "-- Create generic secret workload-cluster-rancher-kubeconfig with the generated kubeconfig"
kubectl -n cattle-system  create secret generic workload-cluster-rancher-kubeconfig --from-file=/tmp/kubeconfig

echo "-- All done"
