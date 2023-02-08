#!/bin/bash

source tools/shell-lib/common.sh

ENV_NAME=${ENV_NAME:-$1}
if [[ ! -f environment-values/${ENV_NAME}/kustomization.yaml ]]; then
    echo "Usage: $0 [env_name]"
    echo "This script expects to find a kustomisation in environment-values/${ENV_NAME} directory to generate management-cluster configuration and secrets"
    exit 1
fi

export CURRENT_COMMIT=${CI_COMMIT_SHA:-$(git rev-parse HEAD)}

if [[ -z ${GITLAB_USER} || -z ${GITLAB_TOKEN} ]]; then
    echo "GITLAB_USER and GITLAB_TOKEN variables must be defined (token must grant read access to repositories and regitries)"
    exit 1
fi

# Kill all child processes (kubectl watches) on exit
#trap "jobs -rp | xargs -r kill" SIGINT SIGTERM EXIT
[[ ! $CI ]] &&  trap "killall kubectl -q"  EXIT
set -eu

# FIXME: check if script has not already run & pivot (and exit in that case)

# Let env-specific scripts perform ad-hoc tasks
[[ -f ./tools/bootstrap/${ENV_NAME}.sh ]] && source ./tools/bootstrap/${ENV_NAME}.sh

echo_b "\U0001F512 Create management cluster secrets and configmaps"
kubectl kustomize environment-values/${ENV_NAME} | envsubst | kubectl apply -f -

echo_b "\U0001F5D8 Bootstraping flux"
kubectl kustomize kustomize-components/flux-system | envsubst | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux to be ready..."
kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment

# Watch flux resources in background
for kind in gitrepositories kustomizations helmreleases helmcharts; do
    kubectl get $kind --show-kind --no-headers -A -w | sed 's/^/bootstrap /' &
done

echo_b "\U0001F4DC Install telco-cloud-init Helm release"
if kubectl get helmreleases.helm.toolkit.fluxcd.io telco-cloud-init &>/dev/null; then
    # Ask flux to reconcile
    kubectl annotate --overwrite helmrelease/telco-cloud-init reconcile.fluxcd.io/requestedAt="$(date +%s)"
else
    kubectl kustomize kustomize-components/telco-cloud-init/bootstrap/ | envsubst | kubectl apply -f -
fi

# Starting from here, the script will just be following components & cluster deployment :)

echo_b "\U000023F3 Wait for Helm chart to be ready"

kubectl wait --for condition=Ready --timeout 300s --all gitrepositories
kubectl wait --for condition=Ready --timeout 300s --all helmcharts
kubectl wait --for condition=Ready --timeout 300s --all helmrelease

echo_b "\U000023F3 Wait for flux to apply management cluster definition"
kubectl wait --for condition=Ready --timeout 300s kustomization cluster

#FIXME: following wait should not be necessary, we should figure out why flux healthchecks on cluster don't work properly
echo_b "\U000023F3 Wait for management cluster to be ready"
kubectl wait --for condition=Ready --timeout 600s cluster management-cluster

# Retrieve maangement cluster secret
kubectl get secret management-cluster-kubeconfig -o jsonpath='{.data.value}' | base64 -d > management-cluster-kubeconfig

echo_b "\U000023F3 Wait for flux fo be installed on management cluster"
kubectl wait --for condition=Ready --timeout 1200s kustomization management-cluster-flux

for kind in gitrepositories kustomizations helmreleases; do
    kubectl --kubeconfig management-cluster-kubeconfig get $kind --show-kind --no-headers -A -w | sed 's/^/management /' &
done

echo_b "\U000023F3 Wait for remaining components to be installed on management cluster and pivot"
kubectl wait --for condition=Ready --timeout 1200s --all kustomizations

echo_b "\U00002714 Management cluster is ready"
kubectl --kubeconfig management-cluster-kubeconfig get nodes

echo_b "\U0001F389 All done"
