#!/bin/bash

# This script provides a way to get some logs from cluster's nodes
# It runs a deamonset creating pods with root access to the node's filesystem

set -eu
set -o pipefail
export SCRIPT_DIR="$(realpath $(dirname $0))"

if [ -n "${1:-}" ]; then
    TARGET_DIR="$1"
else
    echo >&2 "[ERROR] No target directory provided"
    echo >&2 "usage: $0 <target_dir>"
fi

function on_exit() {
    kubectl delete -f "${SCRIPT_DIR}/dump_deamonset.yaml"
}
trap on_exit EXIT

echo >&2 "# Dumping nodes logs"
echo >&2 ">> Creating node_dump daemonset"
kubectl apply -f "${SCRIPT_DIR}/dump_deamonset.yaml"

echo >&2 ">> Wait pods to be ready"
NODE_COUNT=$(kubectl get nodes -oyaml | yq '.items | length')
kubectl wait -n node-dump --for="jsonpath={.status.numberReady}=$NODE_COUNT" daemonset/node-dump

echo >&2 ">> Copy logs files in directory $TARGET_DIR"
PODS=$(kubectl get pods -n node-dump -o yaml)
for pod_name in $(echo "$PODS" | yq '.items[] | .metadata.name'); do
    export pod_name=$pod_name
    node_name=$(echo "$PODS" | yq '.items[] | select(.metadata.name == strenv(pod_name)) | .spec.nodeName' )
    echo >&2 ">>>> Copy logs for node $node_name via pod $pod_name"
    mkdir -p $TARGET_DIR/$node_name
    kubectl cp -n node-dump $pod_name:/tmp/dump/ $TARGET_DIR/$node_name &> /dev/null
done
