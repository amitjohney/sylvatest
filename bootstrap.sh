#!/bin/bash

source tools/shell-lib/common.sh

if [[ ${KUBECONFIG:-} =~ management-cluster-kubeconfig ]]; then
    echo -e "KUBECONFIG seems to point to the management cluster, which doesn't sound ok for 'bootstrap.sh'\n(KUBECONFIG=$KUBECONFIG)"
    exit 1
fi

validate_input_values

check_pivot_has_ran

echo_b "\U0001F503 Preparing bootstrap cluster"
tools/kind/bootstrap-cluster.sh

ensure_flux

echo_b "\U0001F50E Validate sylva-units values for management cluster"
validate_sylva_units

echo_b "\U0001F5D1 Delete preview chart and namespace"
cleanup_preview

set_current_namespace sylva-system

echo_b "\U0001F4DC Install sylva-units Helm release and associated resources"
_kustomize ${ENV_PATH} | \
  define_source | \
  inject_bootstrap_values | \
  kubectl apply -f -

echo_b "\U0001F3AF Trigger reconciliation of units"
# this is just to force-refresh on refreshed parameters
force_reconcile helmrelease sylva-units

# Attempt to retrieve management-cluster-kubeconfig in background
retrieve_kubeconfig &
KUBECONFIG_PID=$!

echo_b "\U000023F3 Wait for bootstrap units and management cluster to be ready"
sylvactl watch \
  --reconcile \
  --timeout $(ci_remaining_minutes_and_at_most ${BOOTSTRAP_WATCH_TIMEOUT_MIN:-30}) \
  ${SYLVACTL_SAVE:+--save bootstrap-timeline.html} \
  Kustomization/sylva-system/management-sylva-units

if kill $KUBECONFIG_PID &>/dev/null; then
    echo_b "\U00002717 Failed to retrieve management-cluster kubeconfig"
    exit 1
fi

echo_b "\U000023F3 Wait for units installed on management cluster to be ready"
sylvactl watch \
  --reconcile \
  --kubeconfig management-cluster-kubeconfig \
  --timeout $(ci_remaining_minutes_and_at_most ${MGMT_WATCH_TIMEOUT_MIN:-45}) \
  ${SYLVACTL_SAVE:+--save management-cluster-timeline.html}

echo_b "\U00002714 Sylva is ready, everything deployed in management cluster"
echo "   Management cluster nodes:"
kubectl --kubeconfig management-cluster-kubeconfig get nodes

echo_b "\U0001F331 You can access following UIs"
kubectl --kubeconfig management-cluster-kubeconfig get ingress --all-namespaces

echo_b "\U0001F389 All done"
