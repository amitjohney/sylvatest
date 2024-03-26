#!/bin/bash

set -e
export BASE_DIR="$(realpath $(dirname $0)/.. )"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: ./workload-cluster-cleanup.sh <WORKLOAD_CLUSTER_NAMESPACE > <(optionally)IReallyWantToDelete>"
    exit 1
fi

WORKLOAD_CLUSTER_NAMESPACE=$1

if [ "$#" -eq 2 ]; then
    CONFIRMATION=$2
else
    echo "Are you sure you want to delete workload cluster in namespace \"$WORKLOAD_CLUSTER_NAMESPACE\"? (Type 'IReallyWantToDelete' to confirm)"
    read -r CONFIRMATION
fi

if [[ $CONFIRMATION != "IReallyWantToDelete" ]]; then
  echo "Operation not confirmed by user. Type 'IReallyWantToDelete' to confirm"
  exit 0
fi

echo "Running workload-cluster-cleanup.sh from dir: ${BASE_DIR}"

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
    exit 1
fi

WORKLOAD_CLUSTER_NAME=$(kubectl -n $WORKLOAD_CLUSTER_NAMESPACE get cluster -o name)

echo "Deleting workload cluster named \"$WORKLOAD_CLUSTER_NAME\" in namespace \"$WORKLOAD_CLUSTER_NAMESPACE\""
flux suspend --all ks -n $WORKLOAD_CLUSTER_NAMESPACE
flux suspend --all hr -n $WORKLOAD_CLUSTER_NAMESPACE
kubectl delete --request-timeout 5m -n $WORKLOAD_CLUSTER_NAMESPACE hr cluster
if kubectl get -n $WORKLOAD_CLUSTER_NAMESPACE heatstacks &> /dev/null; then
    echo "Found heatstacks in namespace $WORKLOAD_CLUSTER_NAMESPACE, deleting..."
    kubectl delete --request-timeout 1m -n $WORKLOAD_CLUSTER_NAMESPACE heatstacks heatstack-capo-cluster-resources
fi
kubectl delete --request-timeout 1m ns $WORKLOAD_CLUSTER_NAMESPACE
echo "Successfully deleted workload cluster in namespace \"$WORKLOAD_CLUSTER_NAMESPACE\""
