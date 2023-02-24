#!/bin/bash

# Helper script used to clean management cluster openstack resources. USE WITH CARE, AT YOU OWN RISK

set -o xtrace

OS_ARGS=""
PLATFORM=$1
if [ ! -z $PLATFORM ]; then
  OS_ARGS="--os-cloud $PLATFORM --insecure"
fi

if openstack ${OS_ARGS} endpoint list &> /dev/null; then
    echo "This script should not be run with admin role, otherwise it may impact other tenants"
    exit 1
fi

openstack ${OS_ARGS} server list -f value | awk '$2~/^(management|(first|test)-workload)-cluster-/ {print $1}' | xargs -t -r openstack ${OS_ARGS} server delete --wait
openstack ${OS_ARGS} port list -f value | awk '$2~/^(management|(first|test)-workload)-cluster-/ {print $1}' | xargs -t -r openstack ${OS_ARGS} port delete
openstack ${OS_ARGS} security group list -f value | awk '$2~/^k8s-cluster-default-(management|(first|test)-workload)-cluster-/ {print $1}' | xargs -tr openstack ${OS_ARGS} security group delete
