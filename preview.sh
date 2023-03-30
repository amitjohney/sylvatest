#!/bin/bash

source tools/shell-lib/common.sh

if ! command -v helm &>/dev/null; then
    echo "helm binary is required by this tool, please install it"
    exit 1
fi

echo_b "\U0001F5D8 Bootstraping flux"
kubectl kustomize kustomize-units/flux-system/bootstrap | envsubst | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux to be ready..."
kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment

echo_b "\U0001F4DD Create bootstrap configmap for bootstrap values validation"
kubectl -n sylva-units-preview create configmap management-cluster-bootstrap-values --from-file=${BASE_DIR}/charts/sylva-units/bootstrap.values.yaml

echo_b "\U0001F4C1 Create & install sylva-units preview Helm release"
validate_sylva_units

echo_b "\U000023F3 Retrieve chart user values"
helm get values -n sylva-units-preview sylva-units

echo_b "\U000023F3 Retrieve the final set of values (after gotpl rendering)"
kubectl get secrets -n sylva-units-preview sylva-units-values-debug -o template="{{ .data.values }}" | base64 -d

echo_b "\U000023F3 Delete preview chart and namespace"
kubectl delete -n sylva-units-preview helmrelease/sylva-units gitrepository/sylva-core configmap/management-cluster-bootstrap-values
kubectl delete namespace sylva-units-preview
