#!/bin/bash

# Helper script used to clean management cluster openstack resources
# USE WITH CARE, AT YOU OWN RISK, especially the last line that cleans up _all_ available volumes can be dangerous...

#set -eux
set -o xtrace

OS_ARGS=""
PLATFORM=$1
if [ ! -z $PLATFORM ]; then
  OS_ARGS="--os-cloud $PLATFORM"
fi

if openstack ${OS_ARGS} endpoint list &> /dev/null; then
    echo "This script should not be run with admin role, otherwise it may impact other tenants"
    exit 1
fi

openstack ${OS_ARGS} server list -f value | awk '$2~/^(management|first-workload)-cluster-/ {print $1}' | xargs -r openstack ${OS_ARGS} server delete --wait

openstack ${OS_ARGS} floating ip list --long -f value |awk '/cluster-api-provider-openstack/ {print $1}' | xargs -r openstack ${OS_ARGS} floating ip delete

for router in $(openstack ${OS_ARGS} router list -f value | awk '$2~/^k8s-clusterapi/ {print $1}'); do
    for subnet in $(openstack ${OS_ARGS} subnet list -f value | awk '$2~/^k8s-clusterapi/ {print $1}'); do
        openstack ${OS_ARGS} router remove subnet $router $subnet || true
    done
done

for net in $(openstack ${OS_ARGS} network list -f value | awk '$2~/^k8s-cluster/ {print $1}'); do
    openstack ${OS_ARGS} port list --network $net -f value  | awk '{print $1}' | xargs -r openstack ${OS_ARGS} port delete
    openstack ${OS_ARGS} network delete $net
done

openstack ${OS_ARGS} router list -f value | awk '$2~/^k8s-clusterapi/ {print $1}' | xargs -r openstack ${OS_ARGS} router delete

openstack ${OS_ARGS} security group list -f value | awk '$2~/^k8s-clusterapi/ {print $1}' | xargs -r openstack ${OS_ARGS} security group delete

openstack ${OS_ARGS} volume list -f value | awk '$2=/available/ {print $1}' | xargs -r openstack ${OS_ARGS} volume delete
