echo_b() {
  echo -e "\e[1m$@\e[0m"
}

function background_watch() {
  local output_prefix=$1
  shift
  for kind in $@; do
    kubectl ${kubectl_additional_args:-} get $kind --show-kind --no-headers -A -w | sed "s/^/$output_prefix /" &
  done
}

if ! [[ $# -eq 1 && -f ${1}/kustomization.yaml ]]; then
    echo "Usage: $0 [env_name]"
    echo "This script expects to find a kustomisation in [env_name] directory to generate management-cluster configuration and secrets"
    exit 1
else
    ENV_PATH=$(readlink -f $1)
fi

export CURRENT_COMMIT=${CI_COMMIT_SHA:-$(git rev-parse HEAD)}

if [[ -z ${GITLAB_USER} || -z ${GITLAB_TOKEN} ]]; then
    echo "GITLAB_USER and GITLAB_TOKEN variables must be defined (token must grant read access to repositories and regitries)"
    exit 1
fi

set -eu

# Source env-specific scripts to perform ad-hoc tasks if required
[[ -f ${ENV_PATH}/hacks.sh ]] && source ${ENV_PATH}/hacks.sh

trap 'pids="$(jobs -rp)"; [ -n "$pids" ] && kill $pids' EXIT

BASE_DIR="$(realpath $(dirname $0))"

function exit_trap() {
    # Call debug script if needed
    if [[ $? -ne 0 && ${DEBUG_ON_EXIT:-"0"} -eq 1 ]]; then
        echo_b "gathering debugging logs in debug-on-exit.log file"
        ${BASE_DIR}/tools/shell-lib/debug-on-exit.sh > debug-on-exit.log
    fi

    # Kill all child processes (kubectl watches) on exit
    pids="$(jobs -rp)"
    [ -n "$pids" ] && kill $pids
}
trap exit_trap EXIT


function force_reconcile_and_wait() {
  local kinds=$1
  local name_or_selector=$2
  echo "force reconcialiation of $1 $2"
  kubectl annotate --overwrite $kinds $name_or_selector reconcile.fluxcd.io/requestedAt=$(date +%s) | sed -e 's/^/  /'
  echo "waiting for $1 $2 ..."
  kubectl wait --for condition=Ready --timeout=90s $kinds $name_or_selector | sed -e 's/^/  /'
}
