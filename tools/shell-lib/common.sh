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

# Kill all child processes (kubectl watches) on exit
trap 'pids="$(jobs -rp)"; [ -n "$pids" ] && kill $pids' EXIT
