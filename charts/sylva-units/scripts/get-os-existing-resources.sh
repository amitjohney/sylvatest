#!/bin/bash

set -e
set -o pipefail
echo "Initiate ConfigMap manifest file"

configmap_file=/tmp/os-resources-info.yaml

cat <<EOF >> $configmap_file
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${OUTPUT_CONFIGMAP}
  namespace: ${TARGET_NAMESPACE}
  labels:
    sylva.os-resources-info: ""
data:
EOF

echo "Looking for existing resources in Openstack..."
if [[ -n "$VIP" ]]; then
  echo "Looking for Neutron port matching $VIP"
  openstack --os-cloud $CLOUD  port list --fixed-ip ip-address=$VIP --network $NETWORK_ID -f yaml > /tmp/port.yaml 
  LENGTH=$(yq '. | length' /tmp/port.yaml)
  if [[ $LENGTH -gt 0 ]]; then
    UUID=$(yq '.0.ID' /tmp/port.yaml)
    echo "  CLUSTER_VIRTUAL_IP_PORT_UUID: ${UUID}" >> $configmap_file
    echo "    Neutron port found: ${UUID}"
  else
    echo "    Fatal error: Neutron port matching ${VIP} in network ${NETWORK_ID} not found"
    exit 1
  fi
fi
# Update configmap
echo "Updating ${OUTPUT_CONFIGMAP} configmap"
# Unset proxy settings, if any were needed for oras tool, before connecting to local bootstrap cluster
unset https_proxy
kubectl apply -f $configmap_file
