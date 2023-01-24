#!/bin/sh

set -eu

SA_PATH=/var/run/secrets/kubernetes.io/serviceaccount/

cat <<EOF > $(pwd)/source-kubeconfig
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: $(cat $SA_PATH/ca.crt | base64 -w 0)
    server: https://kubernetes
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: default
    user: default-user
current-context: default-context
users:
- name: default-user
  user:
    token: $(cat $SA_PATH/token)
EOF

export KUBECONFIG="$(pwd)/source-kubeconfig"

$(dirname $0)/kube-job.sh

echo "All done"
