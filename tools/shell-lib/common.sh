set -eu
set -o pipefail

export BASE_DIR="$(realpath $(dirname $0))"

echo_b() {
  if (( ${current_section_number:-0} > 0 )) ; then
    echo -e "\e[0Ksection_end:`date +%s`:section_$current_section_number\r\e[0K"
  fi

  current_section_number=$(( ${current_section_number:-0} + 1))
  echo -e "\e[1m\e[0Ksection_start:`date +%s`:section_$current_section_number[collapsed=true]\r\e[0K$@\e[0m"
}

function check_pivot_has_ran() {
  if kubectl wait --for condition=complete --timeout=0s job pivot-job > /dev/null 2>&1; then
    { echo_b "\U000274C The pivot job has already ran and moved resources to the management cluster. Please use apply.sh instead of bootstrap.sh"; exit 1;} || echo
  fi
  if kubectl get customresourcedefinitions.apiextensions.k8s.io kustomizations.kustomize.toolkit.fluxcd.io &>/dev/null; then
    if [ -n "$(kubectl get kustomizations.kustomize.toolkit.fluxcd.io cluster -o jsonpath='{.metadata.annotations.pivot/started}')" ]; then
      { echo_b "\U000274C The pivot job is in progress. Please wait for it to finish."; exit 1;} || echo
    fi
  fi
}

function background_watch() {
  local output_prefix=$1
  shift
  for kind in $@; do
    kubectl ${kubectl_additional_args:-} get $kind --show-kind --no-headers -A -w | grep -Ev "(Reconciliation in progress|Health check failed after|dependency .* is not ready| 0s *$)" | sed "s/^/$output_prefix /" &
  done
}

function kubectl_wait_sylva_units_kustomizations {
    target_revision=$(kubectl get gitrepositories sylva-core -o "jsonpath={.status.artifact.revision}")
    set +e
    kubectl wait kustomization "--for=jsonpath={status.lastAppliedRevision}=$target_revision" $* 2> >(grep -v "lastAppliedRevision is not found")
    err=$?
    set -e
    return $err
}

function sylva_units_kustomizations_wait_loop {
    local output_prefix=$1
    local timeout_minutes=$2
    shift 2
    local more_kubectl_args=$*
    attempts=1
    max_attempts=$((1+timeout_minutes/60))
    until kubectl_wait_sylva_units_kustomizations --timeout 0s $more_kubectl_args -l app.kubernetes.io/instance=sylva-units ; do
        echo "~~~~~ $output_prefix kustomizations (wait $attempts/$max_attempts) ~~~~~"
        set +e
        kubectl get kustomizations $more_kubectl_args -l app.kubernetes.io/instance=sylva-units -o 'custom-columns=NAME:.metadata.name,LAST-APPLIED:.status.lastAppliedRevision,READY-MSG:.status.conditions[?(@.type=="Ready")].message'
        set -e
        echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        ((attempts++)) && ((attempts==max_attempts)) && echo "... timeout waiting on $output_prefix kustomizations" && break
        sleep 30
    done
    return $((attempts==max_attempts))
}

if ! [[ $# -eq 1 && -f ${1}/kustomization.yaml ]]; then
    echo "Usage: $0 [env_name]"
    echo "This script expects to find a kustomisation in [env_name] directory to generate management-cluster configuration and secrets"
    exit 1
else
    ENV_PATH=$(readlink -f $1)
fi

export CURRENT_COMMIT=${CI_COMMIT_SHA:-$(git rev-parse HEAD)}

function exit_trap() {
    EXIT_CODE=$?
    # Call debug script if needed
    if [[ $EXIT_CODE -ne 0 && ${DEBUG_ON_EXIT:-"0"} -eq 1 ]]; then
        echo_b "gathering debugging logs in debug-on-exit.log file"
        ${BASE_DIR}/tools/shell-lib/debug-on-exit.sh > debug-on-exit.log
    fi

    # Kill all child processes (kubectl watches) on exit
    pids="$(jobs -rp)"
    [ -n "$pids" ] && kill $pids || true
    exit $EXIT_CODE
}
trap exit_trap EXIT

function force_reconcile_and_wait() {
  local kinds=$1
  local name_or_selector=$2
  echo "force reconciliation of $1 $2"
  kubectl annotate --overwrite $kinds $name_or_selector reconcile.fluxcd.io/requestedAt=$(date +%s) | sed -e 's/^/  /'
  echo "waiting for $1 $2 ..."
  kubectl wait --for condition=Ready --timeout=90s $kinds $name_or_selector | sed -e 's/^/  /'
}

function validate_sylva_units() {
  # Create & install sylva-units preview Helm release
  PREVIEW_DIR=${BASE_DIR}/sylva-units-preview
  mkdir -p ${PREVIEW_DIR}
  cat <<-EOF > ${PREVIEW_DIR}/kustomization.yaml
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
  kubectl annotate --overwrite -n sylva-units-preview gitrepository/sylva-core reconcile.fluxcd.io/requestedAt="$(date +%s)"
  kubectl annotate --overwrite -n sylva-units-preview helmrelease/sylva-units reconcile.fluxcd.io/requestedAt="$(date +%s)"

  echo "Wait for Helm release to be ready"
  for flux_resource in gitrepository/sylva-core helmchart/sylva-units-preview-sylva-units helmrelease/sylva-units; do
    if ! kubectl wait --for condition=Ready --timeout 100s -n sylva-units-preview $flux_resource; then
        echo "Resource $flux_resource did not become ready in time"
        kubectl get -n sylva-units-preview $flux_resource -o yaml
        exit 1
    fi
  done
}
