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

echo_b "\U0001F4C1 Create & install sylva-units preview Helm release"

PREVIEW_DIR=${BASE_DIR}/sylva-units-preview
mkdir -p ${PREVIEW_DIR}
cat <<EOF > ${PREVIEW_DIR}/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- $(realpath --relative-to=${PREVIEW_DIR} ${ENV_PATH})
components:
- $(realpath --relative-to=${PREVIEW_DIR} ./environment-values/preview)
EOF
kubectl kustomize ${PREVIEW_DIR} | sed "s/CURRENT_COMMIT/${CURRENT_COMMIT}/" | kubectl apply -f -
rm -Rf ${PREVIEW_DIR}

# this is just to force-refresh in a dev environment with a new commit (or refreshed parameters)
kubectl annotate --overwrite -n sylva-units-preview gitrepository/sylva-units reconcile.fluxcd.io/requestedAt="$(date +%s)"
kubectl annotate --overwrite -n sylva-units-preview helmrelease/sylva-units reconcile.fluxcd.io/requestedAt="$(date +%s)"

echo_b "\U000023F3 Wait for Helm release to be ready"
for flux_resource in gitrepository/sylva-units helmchart/sylva-units-preview-sylva-units helmrelease/sylva-units; do
    if ! kubectl wait --for condition=Ready --timeout 100s -n sylva-units-preview $flux_resource; then
        echo_b "\U0001F4A5 Resource $flux_resource did not become ready in time"
        kubectl get -n sylva-units-preview $flux_resource -o yaml
        exit 1
    fi
done

echo_b "\U000023F3 Retrieve chart user values"
helm get values -n sylva-units-preview sylva-units

echo_b "\U000023F3 Retrieve the final set of values (after gotpl rendering)"
kubectl get secrets -n sylva-units-preview sylva-units-values-debug -o template="{{ .data.values }}" | base64 -d

echo_b "\U000023F3 Delete preview chart and namespace"
kubectl delete -n sylva-units-preview helmrelease/sylva-units gitrepository/sylva-units
kubectl delete namespace sylva-units-preview
