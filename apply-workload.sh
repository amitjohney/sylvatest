#!/bin/bash
#
# This script (apply-workload.sh?) can be used to:
# * install the workload-clusters defined at path environment-values/workload-clusters/x using Kustomize
#
# This script will act on the kubectl context of a Sylva management cluster, 
# if the 'management-cluster-kubeconfig' file is found, in which case it will use it, otherwise exit.

source $(dirname $0)/tools/shell-lib/common.sh

validate_input_values

if [[ -f management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${KUBECONFIG:-management-cluster-kubeconfig}
else
    exit -1
fi

ensure_flux

echo_b "\U0001F50E Validate sylva-units values for management cluster"
validate_sylva_units

echo_b "\U0001F5D1 Delete preview chart and namespace"
cleanup_preview

echo_b "\U0001F4DC Install a sylva-units Helm release for workload cluster $(basename ${ENV_PATH})"
kubectl kustomize ${ENV_PATH} | define_source | define_namespace $(basename ${ENV_PATH}) | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux units becoming ready"

sylvactl watch --kubeconfig management-cluster-kubeconfig --reconcile --timeout $(ci_remaining_minutes_and_at_most 20) -n $(basename ${ENV_PATH})

echo_b "\U0001F389 All done"
