#!/bin/bash

set -e
export BASE_DIR="$(realpath $(dirname $0)/.. )"

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "Usage: ./wc-cleanup.sh <Workload-cluster-name> <(optionally)cluster_object_name> <(optionally)IReallyWantToDelete>"
    exit 1
fi

WORKLOAD_CLUSTER=$1
if [[ -z "$2" ]]; then
  CLUSTER="cluster"
else
  CLUSTER=$2
fi

if [ "$#" -eq 3 ]; then
    CONFIRMATION=$3
else
    echo "Are you sure you want to delete workload cluster named \"$WORKLOAD_CLUSTER\" with cluster named \"$CLUSTER\"? (Type 'IReallyWantToDelete' to confirm)"
    read -r CONFIRMATION
fi

if [[ $CONFIRMATION != "IReallyWantToDelete" ]]; then
  echo "Operation not confirmed by user. Type 'IReallyWantToDelete' to confirm"
  exit 0
fi

echo "Running wc-cleanup.sh from dir: ${BASE_DIR}"

if [[ -f ${BASE_DIR}/management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${BASE_DIR}/management-cluster-kubeconfig
else
    echo "management-cluster-kubeconfig file is not present in ${BASE_DIR}"
    exit 1
fi
if [[ -f ${BASE_DIR}/bin/env ]]; then
    source ${BASE_DIR}/bin/env
else
    echo "bin/env is not present in ${BASE_DIR}"
    exit -1
fi

echo "Deleting workload cluster named \"$WORKLOAD_CLUSTER\" with cluster named \"$CLUSTER\""
flux suspend --all ks -n $WORKLOAD_CLUSTER
flux suspend --all hr -n $WORKLOAD_CLUSTER
kubectl delete -n $WORKLOAD_CLUSTER hr $CLUSTER
kubectl delete -n $WORKLOAD_CLUSTER heatstacks heatstack-capo-cluster-resources
kubectl delete ns $WORKLOAD_CLUSTER
echo "Successfully deleted workload cluster named \"$WORKLOAD_CLUSTER\" with cluster named \"$CLUSTER\""
