#!/bin/bash
#
# This script can be used to:
# * install the system on an already existing k8s cluster built in an ad-hoc way
#   (in that case, Flux will be installed if not already present)
# * update the system on a cluster where it is already installed with the bootstrap mechanism
#
# This script will act on whatever is the current kubectl config unless
# the 'management-cluster-kubeconfig' file is found, in which case it will use it.

source $(dirname $0)/tools/shell-lib/common.sh

if [[ -f management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${KUBECONFIG:-management-cluster-kubeconfig}
fi

if ! (kubectl get nodes > /dev/null); then
    echo_b "Cannot access cluster, 'kubectl get nodes' gives:"
    kubectl get nodes
    exit -1
fi

if ! (kubectl get namespace flux-system >/dev/null); then
    echo_b "\U0001F5D8 Bootstraping flux"
    kubectl kustomize kustomize-units/flux-system | envsubst | kubectl apply -f -

    echo_b "\U000023F3 Wait for Flux to be ready..."
    kubectl wait --for condition=Available --timeout 600s -n flux-system --all deployment
fi

echo_b "\U0001F50E Validate sylva-units values for management cluster"
validate_sylva_units

echo_b "\U000023F3 Delete preview chart and namespace"
cleanup_preview

echo_b "\U0001F512 Create or update management cluster secrets and configmaps"
kubectl kustomize ${ENV_PATH} | define_source | kubectl apply -f -

echo_b "\U0001F3AF Trigger reconciliation of Flux units"

# this is just to force-refresh on refreshed parameters
force_reconcile helmrelease sylva-units

echo_b "\U000023F3 Wait for Flux units becoming ready"

sylvactl watch --kubeconfig management-cluster-kubeconfig --reconcile --timeout 20m

echo_b "\U0001F389 All done"
