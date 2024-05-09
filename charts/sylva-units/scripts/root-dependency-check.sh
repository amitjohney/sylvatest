#!/bin/bash
#
# See 'root-dependency' unit for context about what this script does.
#
# This script checks that all Kustomizations in $TARGET_NAMESPACE have been
# freshly updated for the current revision of the Helm release of sylva-units
# and are waiting on their dependency on the corresponding 'root-dependency-<n>'
# Kustomization to be ready.
#
# We apply the following criteria:
# - (a Kustomization named root-dependency-* is ignored)
# - Kustomization has 'root-dependency-$HELM_REVISION' in spec.dependsOn
# - Kustomization has a Ready=False condition

set -e
set -o pipefail


# how long to wait for all Kustomizations to meet the criteria
# (we shouldn't need to wait for long, except that if k8s API is slow
#  it may require sometime to kubectl to see all Kustomizations, and
#  unfortunately it may declare that a Kustomization didn't meet the wait
#  criteria even if just didn't had time to see it)
WAIT_TIMEOUT=$${WAIT_TIMEOUT:-60s}

# we setup an exit trap to display the status of all Kustomization
# if one of the 'kubectl wait' fails
function exit_trap() {
    echo "--- summary of resources"
    kubectl -n $TARGET_NAMESPACE get Kustomizations -l app.kubernetes.io/instance=sylva-units
}
trap exit_trap EXIT

# TODO: check if something special needs to be done on suspended resources ...

echo "--- waiting for Kustomization to be labbeled with sylva-units-helm-revision=$HELM_REVISION"

kubectl -n $TARGET_NAMESPACE wait Kustomization -l app.kubernetes.io/instance=sylva-units --timeout $WAIT_TIMEOUT \
  --for=jsonpath="{.metadata.labels.sylva-units-helm-revision}=$HELM_REVISION"

echo "--- waiting for Kustomization to have a Ready=false condition"

kubectl -n $TARGET_NAMESPACE wait Kustomization -l app.kubernetes.io/instance=sylva-units --timeout $WAIT_TIMEOUT \
  --for condition=Ready=false
