#!/bin/bash

source tools/shell-lib/common.sh

if [[ ${KUBECONFIG:-} =~ management-cluster-kubeconfig ]]; then
    echo -e "KUBECONFIG seems to point to the management cluster, which doesn't sound ok for 'bootstrap.sh'\n(KUBECONFIG=$KUBECONFIG)"
    exit -1
fi

check_pivot_has_ran

echo_b "\U0001F503 Bootstraping flux"
kubectl kustomize kustomize-units/flux-system/bootstrap | envsubst | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux to be ready..."
kubectl wait --for condition=Available --timeout 600s -n flux-system --all deployment

echo_b "\U0001F50E Validate sylva-units values for management cluster"
validate_sylva_units

echo_b "\U000023F3 Delete preview chart and namespace"
kubectl delete -n sylva-units-preview helmrelease/sylva-units gitrepository/sylva-core
kubectl delete namespace sylva-units-preview

echo_b "\U0001F4DD Create bootstrap configmap"
# NOTE(feleouet): as use the same kustomisation for bootstrap and management cluster, pass bootstrap environment values as configmap
# as it won't be labelled with copy-from-bootstrap-to-management, it won't be copied to management-cluster
kubectl create configmap management-cluster-bootstrap-values --from-file=${BASE_DIR}/charts/sylva-units/bootstrap.values.yaml --dry-run=client -o yaml | kubectl apply -f -

echo_b "\U0001F4DC Install sylva-units Helm release"
kubectl kustomize ${ENV_PATH} | sed "s/CURRENT_COMMIT/${CURRENT_COMMIT}/" | kubectl apply -f -

# this is just to force-refresh in a dev environment with a new commit (or refreshed parameters)
kubectl annotate --overwrite gitrepository/sylva-core reconcile.fluxcd.io/requestedAt="$(date +%s)"
kubectl annotate --overwrite helmrelease/sylva-units reconcile.fluxcd.io/requestedAt="$(date +%s)"

# Attempt to retrieve management-cluster-kubeconfig in background
retrieve_kubeconfig &
KUBECONFIG_PID=$!

ensure_sylvactl

echo_b "\U000023F3 Wait for management cluster to be ready"
./sylvactl watch --reconcile --timeout 20m Kustomization/default/sylva-units

if kill $KUBECONFIG_PID &>/dev/null; then
    echo_b "\U00002717 Failed to retrieve management-cluster kubeconfig"
    exit 1
fi

echo_b "\U000023F3 Wait for units installed on management cluster to be ready"
./sylvactl watch --reconcile --kubeconfig management-cluster-kubeconfig --timeout 40m

echo_b "\U00002714 Management cluster is ready"
kubectl --kubeconfig management-cluster-kubeconfig get nodes

echo_b "\U0001F331 You can access following UIs"
kubectl --kubeconfig management-cluster-kubeconfig get ingress --all-namespaces

echo_b "\U0001F389 All done"
