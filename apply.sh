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

validate_input_values

if [[ -f management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${KUBECONFIG:-management-cluster-kubeconfig}
fi

if ! (kubectl get nodes > /dev/null); then
    echo_b "Cannot access cluster, 'kubectl get nodes' gives:"
    kubectl get nodes
    exit -1
fi

ensure_flux

echo_b "\U0001F50E Validate sylva-units values for management cluster"
validate_sylva_units

echo_b "\U0001F5D1 Delete preview chart and namespace"
cleanup_preview

echo_b "\U0001F4DC Update sylva-units Helm release and associated resources"
kubectl kustomize ${ENV_PATH} | define_source | kubectl apply -f -

echo_b "\U0001F3AF Trigger reconciliation of Flux units"

# this is just to force-refresh on refreshed parameters
force_reconcile helmrelease sylva-units

echo_b "\U000023F3 Wait for Flux units becoming ready"

sylvactl watch --kubeconfig management-cluster-kubeconfig --reconcile --timeout $(ci_remaining_minutes_and_at_most 20)

echo_b "\U0001F389 All done"
