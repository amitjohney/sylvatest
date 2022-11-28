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
    # Grab some info in case of failure, essentially usefull to troubleshoot CI, fell free to add your own commands while troubleshooting
    if [[ $? -ne 0 && ${DEBUG_ON_EXIT:-"0"} -eq 1 ]]; then
        echo_b "Docker containers"
        docker ps
        echo_b "System info"
        free -h
        df -h || true
        echo_b "Flux kustomize-controller  logs in bootstrap cluster"
        kubectl logs -n flux-system -l app=kustomize-controller
        echo_b "CAPI logs in bootstrap cluster"
        kubectl logs -n capi-system -l control-plane=controller-manager
        echo_b "CAPD logs in bootstrap cluster"
        kubectl logs -n capd-system -l control-plane=controller-manager
        if [[ -f $BASE_DIR/management-cluster-kubeconfig ]]; then
            export KUBECONFIG=${KUBECONFIG:-$BASE_DIR/management-cluster-kubeconfig}
            echo_b "Get nodes in management cluster"
            kubectl --request-timeout=3s get nodes
            echo_b "Get pods in management cluster"
            kubectl --request-timeout=3s get pods -A
        fi
        echo_b "Dump node logs"
        docker ps -q -f name=management-cluster-control-plane* | xargs -I % -r docker exec % journalctl -e
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
