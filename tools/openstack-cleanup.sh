#!/bin/bash

# Helper script used to clean management and test workload clusters OpenStack resources. USE WITH CARE, AT YOU OWN RISK

OS_ARGS=""
PLATFORM=$1
if [ ! -z $PLATFORM ]; then
  OS_ARGS="--os-cloud $PLATFORM"
fi
OS_ARGS="$OS_ARGS --insecure --os-compute-api-version 2.26"
CAPO_TAG=${2:-sylva-$(openstack ${OS_ARGS} configuration show -f json | jq -r '."auth.username"')}

if openstack ${OS_ARGS} endpoint list &> /dev/null; then
    echo "This script should not be run with admin role, otherwise it may impact other tenants"
    exit 1
fi

echo -e "\U0001F5D1 Start cleanup for tag: ${CAPO_TAG} at $(date)"

SERVERS="$(openstack ${OS_ARGS} server list --tags ${CAPO_TAG} -f value -c Name)"

echo "The following servers match the ${CAPO_TAG}:\n${SERVERS}"

echo -e "\U0001F5D1 Pausing servers: ${SERVERS//$'\n'/ }"
openstack ${OS_ARGS} server pause ${SERVERS//$'\n'/ }
echo -e "\U0001F5D1 Deleting servers: ${SERVERS//$'\n'/ }"
openstack ${OS_ARGS} server delete --wait ${SERVERS//$'\n'/ }
echo -e "\U0001F5D1 Deleting volumes: ${SERVERS//$'\n'/-root }"
openstack ${OS_ARGS} volume delete ${SERVERS//$'\n'/-root } --purge || true

openstack ${OS_ARGS} port list --tags ${CAPO_TAG} -f value -c name -c status -c device_owner -c id | awk '$2=="DOWN" {print $4}' | xargs -tr openstack ${OS_ARGS} port delete || true

openstack ${OS_ARGS} security group list --tags ${CAPO_TAG} -f value -c ID | xargs -tr openstack ${OS_ARGS} security group delete || true

for vol in $(openstack ${OS_ARGS} volume list --status available -f value -c Name | grep '^pvc'); do
    vol_property=$(openstack ${OS_ARGS} volume show $vol -c properties -f json | jq '.properties."cinder.csi.openstack.org/cluster"' -r)
    if [ "${vol_property}" = "${CAPO_TAG}" ]; then
        echo "openstack ${OS_ARGS} volume delete $vol --purge"
        openstack ${OS_ARGS} volume delete $vol --purge
    fi
done

if [ -n "$(openstack ${OS_ARGS} server list -f value --tags ${CAPO_TAG})" ]; then
    echo "The following CAPO machines tagged ${CAPO_TAG} were not removed, please try again, and delete the corresponding stacks"
    openstack ${OS_ARGS} server list --tags ${CAPO_TAG} -f value -c Name
    exit 1
else
    openstack ${OS_ARGS} stack list --tags ${CAPO_TAG} -f value -c ID | xargs -tr openstack ${OS_ARGS} stack delete || true
fi
