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
kubectl annotate --overwrite gitrepository/sylva-core reconcile.fluxcd.io/requestedAt="$(date -uIs)"
kubectl annotate --overwrite helmrelease/sylva-units reconcile.fluxcd.io/requestedAt="$(date -uIs)"

# Attempt to retrieve management-cluster-kubeconfig in background
retrieve_kubeconfig &
KUBECONFIG_PID=$!

ensure_sylvactl

echo_b "\U000023F3 Wait for management cluster to be initialized [1/2]"
# because 'cluster' unit becomes true too early, before the kubeconfig is produced
# waiting for calico unit is a temporary workaround
./sylvactl watch --reconcile --timeout 20m Kustomization/default/calico

echo_b "\U000023F3 Wait for management cluster to be initialized [2/2]"

./sylvactl watch --reconcile --timeout 20m Kustomization/default/management-cluster-flux

if kill $KUBECONFIG_PID &>/dev/null; then
    echo_b "\U00002717 Failed to retrieve management-cluster kubeconfig"
    exit 1
else
    echo_b "\U0001F4C4 management-cluster-kubeconfig file has been retrieved!"
fi

# wait for pivot to be feasible
echo_b "\U000023F3 Wait for pivot to be feasible"
./sylvactl watch --reconcile --kubeconfig management-cluster-kubeconfig --timeout 5m Kustomization/default/mgmt-capi-providers-ready

# TODO: choice up to the user + messages + env varible / CI
echo_b "\U000023F3 Wait for pivot to be done"
./sylvactl watch --reconcile --timeout 15m Kustomization/default/pivot

echo_b "\U0001FAA6 Destroy bootstrap cluster"
kind delete cluster --name bootstrap

echo_b "\U000023F3 Wait for units installed on management cluster to be ready"
./sylvactl watch --reconcile --kubeconfig management-cluster-kubeconfig --timeout 30m

echo_b "\U00002714 Sylva is ready, everything deployed in management cluster (including test workload cluster definition, if enabled)"
echo "   Management cluster nodes:"
kubectl --kubeconfig management-cluster-kubeconfig get nodes

echo_b "\U0001F331 You can access following UIs"
kubectl --kubeconfig management-cluster-kubeconfig get ingress --all-namespaces

echo_b "\U0001F389 All done"
