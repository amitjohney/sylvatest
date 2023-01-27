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
    kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment
fi

echo_b "\U0001F512 Create or update management cluster secrets and configmaps"
kubectl kustomize ${ENV_PATH} | sed "s/CURRENT_COMMIT/${CURRENT_COMMIT}/" | kubectl apply -f -

echo_b "\U0001F3AF Trigger reconciliation of Flux units"

# this is just to force-refresh with a new commit (or refreshed parameters)

force_reconcile_and_wait gitrepository sylva-core

force_reconcile_and_wait helmrelease sylva-units

force_reconcile_and_wait gitrepositories             "-l app.kubernetes.io/instance=sylva-units"

force_reconcile_and_wait kustomizations,helmreleases "-l app.kubernetes.io/instance=sylva-units"

# Starting from here, the script will just be following Flux units

echo_b "\U000023F3 Wait for Flux units becoming ready"

background_watch "    " gitrepositories kustomizations helmreleases helmcharts
kubectl wait --for condition=Ready --timeout 1200s --all kustomizations,helmreleases

echo_b "\U0001F389 All done"
