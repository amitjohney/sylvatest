#!/bin/bash

source tools/shell-lib/common.sh

if ! command -v helm &>/dev/null; then
    echo "helm binary is required by this tool, please install it"
    exit 1
fi

echo_b "\U0001F503 Preparing bootstrap cluster"
tools/kind/bootstrap-cluster.sh

ensure_flux

echo_b "\U0001F4C1 Create & install sylva-units preview Helm release"
validate_sylva_units

echo_b "\U000023F3 Retrieve chart user values"
helm get values -n sylva-units-preview sylva-units

echo_b "\U000023F3 Retrieve the final set of values (after gotpl rendering)"
kubectl get secrets -n sylva-units-preview sylva-units-values-debug -o template="{{ .data.values }}" | base64 -d

echo_b "\U0001F5D1 Delete preview chart and namespace"
cleanup_preview
