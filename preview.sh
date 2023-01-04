#!/bin/bash

source tools/shell-lib/common.sh

if ! command -v helm &>/dev/null; then
    echo "helm binary is required by this tool, please install it"
    exit 1
fi

echo_b "\U0001F5D8 Bootstraping flux"
kubectl kustomize kustomize-components/flux-system | envsubst | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux to be ready..."
kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment

echo_b "\U0001F4C1 Create & install telco-cloud-init preview Helm release"

PREVIEW_DIR=${BASE_DIR}/telco-cloud-init-preview
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
kubectl annotate --overwrite -n telco-cloud-init-preview gitrepository/telco-cloud-init reconcile.fluxcd.io/requestedAt="$(date +%s)"
kubectl annotate --overwrite -n telco-cloud-init-preview helmrelease/telco-cloud-init reconcile.fluxcd.io/requestedAt="$(date +%s)"

echo_b "\U000023F3 Wait for Helm chart to be ready"
for flux_resource in gitrepository/telco-cloud-init helmchart/telco-cloud-init-preview-telco-cloud-init helmrelease/telco-cloud-init; do
    if ! kubectl wait --for condition=Ready --timeout 100s -n telco-cloud-init-preview $flux_resource; then
        echo_b "\U0001F4A5 Resource $flux_resource did not become ready in time"
        kubectl get -n telco-cloud-init-preview $flux_resource -o yaml
        exit 1
    fi
done

echo_b "\U000023F3 Retrieve chart user values"
helm get values -n telco-cloud-init-preview telco-cloud-init

echo_b "\U000023F3 Retrieve the final set of values (after gotpl rendering)"
kubectl get secrets -n telco-cloud-init-preview telco-cloud-init-values-debug -o template="{{ .data.values }}" | base64 -d

echo_b "\U000023F3 Delete preview chart and namespace"
kubectl delete -n telco-cloud-init-preview helmrelease/telco-cloud-init gitrepository/telco-cloud-init
kubectl delete namespace telco-cloud-init-preview
