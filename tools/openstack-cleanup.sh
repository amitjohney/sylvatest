#!/bin/bash

# Helper script used to clean management and test workload clusters OpenStack resources. USE WITH CARE, AT YOU OWN RISK

set -o xtrace

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

openstack ${OS_ARGS} server list --tags ${CAPO_TAG} -f value -c Name | awk '{print $1}' | xargs -r openstack ${OS_ARGS} server delete --wait

openstack ${OS_ARGS} port list --tags ${CAPO_TAG} -f value -c name -c status -c device_owner -c id | awk '$2=="DOWN" {print $4}' | xargs -r openstack ${OS_ARGS} port delete || true

openstack ${OS_ARGS} security group list --tags ${CAPO_TAG} -f value -c ID | xargs -r openstack ${OS_ARGS} security group delete || true

openstack ${OS_ARGS} stack list --tags ${CAPO_TAG} -f value -c ID | xargs -r openstack ${OS_ARGS} stack delete || true

if [[ $(openstack ${OS_ARGS} server list --tags ${CAPO_TAG}) ]]; then
    echo "There CAPO machines tagged ${CAPO_TAG} were not removed, please try again"
    exit 1
fi
