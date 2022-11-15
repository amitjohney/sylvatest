#!/bin/bash

source tools/shell-lib/common.sh

echo_b "\U0001F512 Create management cluster secrets and configmaps"
kubectl kustomize ${ENV_PATH} | envsubst | kubectl apply -f -

echo_b "\U0001F5D8 Bootstraping flux"
kubectl kustomize kustomize-components/flux-system | envsubst | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux to be ready..."
kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment

background_watch bootstrap gitrepositories kustomizations helmreleases helmcharts

echo_b "\U0001F4DC Install telco-cloud-init Helm release"
kubectl kustomize kustomize-components/telco-cloud-init/bootstrap | envsubst | kubectl apply -f -

# this is just to force-refresh in a dev environment with a new commit (or refreshed parameters)
kubectl annotate --overwrite gitrepository/telco-cloud-init reconcile.fluxcd.io/requestedAt="$(date +%s)"
kubectl annotate --overwrite helmrelease/telco-cloud-init reconcile.fluxcd.io/requestedAt="$(date +%s)"

# Starting from here, the script will just be following components & cluster deployment :)

echo_b "\U000023F3 Wait for Helm chart to be ready"

kubectl wait --for condition=Ready --timeout 300s --all gitrepositories,helmcharts,helmrelease

echo_b "\U000023F3 Wait for flux to apply management cluster definition"
kubectl wait --for condition=Ready --timeout 300s kustomization cluster

#FIXME: following wait should not be necessary, we should figure out why flux healthchecks on cluster don't work properly
echo_b "\U000023F3 Wait for management cluster to be ready"
kubectl wait --for condition=Ready --timeout 600s cluster management-cluster

# Retrieve maangement cluster secret
kubectl get secret management-cluster-kubeconfig -o jsonpath='{.data.value}' | base64 -d > management-cluster-kubeconfig

echo_b "\U000023F3 Wait for flux to be installed on management cluster"
kubectl wait --for condition=Ready --timeout 1200s kustomization management-cluster-flux

kubectl_additional_args="--kubeconfig management-cluster-kubeconfig" background_watch management gitrepositories kustomizations helmreleases helmcharts

echo_b "\U000023F3 Wait for remaining components to be installed on management cluster and pivot"
kubectl wait --for condition=Ready --timeout 1200s --all kustomizations

echo_b "\U000023F3 Wait for components installed on management cluster to be ready"
kubectl --kubeconfig management-cluster-kubeconfig wait --for condition=Ready --timeout 1200s --all kustomizations

echo_b "\U00002714 Management cluster is ready"
kubectl --kubeconfig management-cluster-kubeconfig get nodes

echo_b "\U0001F389 All done"
