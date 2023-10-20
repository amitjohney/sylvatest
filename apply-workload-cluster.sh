#!/bin/bash
#
# This script can be used to:
# * install the workload-clusters defined at path environment-values/workload-clusters/x using Kustomize
#
# This script will act on the kubectl context of a Sylva management cluster,
# if the 'management-cluster-kubeconfig' file is found, in which case it will use it, otherwise exit.

source $(dirname $0)/tools/shell-lib/common.sh

validate_input_values

if [[ -f management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${KUBECONFIG:-management-cluster-kubeconfig}
else
    echo_b "management-cluster-kubeconfig file is not present in ${PWD}"
    exit -1
fi

if ! (kubectl get nodes > /dev/null); then
    echo_b "Cannot access cluster, 'kubectl get nodes' gives:"
    kubectl get nodes
    exit -1
fi

if ! (kubectl get cm sylva-units-status > /dev/null); then
   echo_b "The sylva-units-status configmap doesn't exist. Please check the status of the management-cluster"
   exit -1
fi

echo_b "\U0001F50E Validate sylva-units values for workload cluster"
validate_sylva_units

echo_b "\U0001F5D1 Delete preview chart and namespace"
cleanup_preview

echo_b "\U0001F4DC Install a sylva-units Helm release for workload cluster $(basename ${ENV_PATH})"
kubectl kustomize ${ENV_PATH} | define_source | set_wc_namespace | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux units becoming ready"
sylvactl watch --kubeconfig management-cluster-kubeconfig --reconcile --timeout $(ci_remaining_minutes_and_at_most 20) -n $(basename ${ENV_PATH})

echo_b "\U0001F389 All done"
