#!/bin/bash
#
# This script can be used to:
# * install the system on an already existing k8s cluster built in an ad-hoc way
#   (in that case, Flux will be installed if not already present)
# * update the system on an cluster where it is already installed with the boostrap mechanim
#
# This script will act on whatever is the current kubectl config unless
# the 'management-cluster-kubeconfig' file is found, in which case it will use it.

source $(dirname $0)/tools/shell-lib/common.sh

if ! (kubectl get nodes > /dev/null); then
    echo_b "Cannot access cluster, 'kubectl get nodes' gives:"
    kubectl get nodes
    exit -1
fi

if ! (kubectl get namespace flux-system >/dev/null); then
    echo_b "\U0001F5D8 Bootstraping flux"
    kubectl kustomize kustomize-components/flux-system | envsubst | kubectl apply -f -

    echo_b "\U000023F3 Wait for Flux to be ready..."
    kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment
fi

echo_b "\U0001F4DC Start watching Flux resources in the background"
background_watch "    " gitrepositories kustomizations helmreleases helmcharts

echo_b "\U0001F512 Create or update management cluster secrets and configmaps"
kubectl kustomize ${ENV_PATH} | envsubst | kubectl apply -f -

echo_b "\U0001F4DC Install or update telco-cloud-init Helm release"
kubectl kustomize kustomize-components/telco-cloud-init/base | envsubst | kubectl apply -f -

# this is just to force-refresh with a new commit (or refreshed parameters)
kubectl annotate --overwrite gitrepository/telco-cloud-init reconcile.fluxcd.io/requestedAt="$(date +%s)"
kubectl annotate --overwrite helmrelease/telco-cloud-init reconcile.fluxcd.io/requestedAt="$(date +%s)"

# Starting from here, the script will just be following Flux components

echo_b "\U000023F3 Wait for Flux components ready"
kubectl wait --for condition=Ready --timeout 1200s --all kustomizations

echo_b "\U0001F389 All done"
