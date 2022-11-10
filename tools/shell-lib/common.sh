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

if [[ ! $# -eq 1 && -f ${1}/kustomization.yaml ]]; then
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

# Kill all child processes (kubectl watches) on exit
trap 'pids="$(jobs -rp)"; [ -n "$pids" ] && kill $pids' EXIT

