#!/bin/bash

source tools/shell-lib/common.sh

debug_on_exit_trigger

check_pivot_has_ran

echo_b "\U0001F503 Bootstraping flux"
kubectl kustomize kustomize-units/flux-system/bootstrap | envsubst | kubectl apply -f -

echo_b "\U000023F3 Wait for Flux to be ready..."
kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment

echo_b "\U0001F4DD Create bootstrap configmap"
# NOTE(feleouet): as use the same kustomisation for bootstrap and management cluster, pass bootstrap environment values as configmap
# as it won't be labelled with copy-from-bootstrap-to-management, it won't be copied to management-cluster
kubectl create configmap management-cluster-bootstrap-values --from-file=${BASE_DIR}/charts/sylva-units/bootstrap.values.yaml --dry-run=client -o yaml | kubectl apply -f -

echo_b "\U0001F4DC Install sylva-units Helm release"
kubectl kustomize ${ENV_PATH} | sed "s/CURRENT_COMMIT/${CURRENT_COMMIT}/" | kubectl apply -f -

# An alternative to the previous 2 commands could be to patch kustomization on the fly using yq:
#kubectl kustomize . | yq 'select(.kind == "HelmRelease").spec.valuesFiles += ["charts/sylva-units/bootstrap.values.yaml"] | \
#                          select(.kind == "GitRepository").spec.ref = {"commit": "'${CURRENT_COMMIT}'"}' | kubectl apply -f -

background_watch bootstrap gitrepositories kustomizations helmreleases helmcharts

# this is just to force-refresh in a dev environment with a new commit (or refreshed parameters)
kubectl annotate --overwrite gitrepository/sylva-core reconcile.fluxcd.io/requestedAt="$(date +%s)"
kubectl annotate --overwrite helmrelease/sylva-units reconcile.fluxcd.io/requestedAt="$(date +%s)"

# Starting from here, the script will just be following units & cluster deployment :)

echo_b "\U000023F3 Wait for Helm release to be ready"

kubectl wait --for condition=Ready --timeout 300s --all gitrepositories,helmcharts,helmrelease

echo_b "\U000023F3 Wait for flux to apply management cluster definition"
kubectl wait --for condition=Ready --timeout 300s kustomization cluster

#FIXME: following wait should not be necessary, we should figure out why flux healthchecks on cluster don't work properly
echo_b "\U000023F3 Wait for management cluster to be ready"
kubectl wait --for condition=ControlPlaneReady --timeout 1200s cluster management-cluster

# Retrieve management cluster secret
orig_umask=$(umask)
umask og-rw
kubectl get secret management-cluster-kubeconfig -o jsonpath='{.data.value}' | base64 -d > management-cluster-kubeconfig
umask $orig_umask

echo_b "\U000023F3 Wait for flux to be installed on management cluster"
kubectl wait --for condition=Ready --timeout 1200s kustomization management-cluster-flux

kubectl_additional_args="--kubeconfig management-cluster-kubeconfig" background_watch management gitrepositories kustomizations helmreleases helmcharts

echo_b "\U000023F3 Wait for base units to be installed on management cluster"
kubectl wait --for condition=Ready --timeout 1800s kustomization sylva-units

echo_b "\U000023F3 Wait for pivot job to start"
attempts=0
max_attempts=50
until kubectl get job pivot-job >/dev/null 2>&1
do
  sleep 10
  echo "Waiting for pivot job to start ($attempts/$max_attempts)"
  ((attempts++)) && ((attempts==max_attempts)) && echo "Timeout waiting for pivot job" && break
done

echo_b "\U000023F3 Wait for pivot to be done"
kubectl wait job pivot-job --for=condition=Complete --timeout 600s

echo_b "\U000023F3 Wait for remaining units installed on management cluster to be ready"
sylva_units_kustomizations_wait_loop management 2200 --kubeconfig management-cluster-kubeconfig

echo_b "\U00002714 Management cluster is ready"
kubectl --kubeconfig management-cluster-kubeconfig get nodes

echo_b "\U0001F331 You can access following UIs"
kubectl --kubeconfig management-cluster-kubeconfig get ingress --all-namespaces

echo_b "\U0001F389 All done"
