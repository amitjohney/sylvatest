#!/bin/bash

set -eu

# Make sure containerd reloads proxy env files
systemctl daemon-reload
systemctl restart containerd

# Clear proxy vars before kubeadm init, otherwise they'll be passed to api-server deployment by kubeadm
unset http_proxy https_proxy no_proxy

# Bootstrap cluster
kubeadm init --kubernetes-version v1.25.6 || true # match with embeeded images if possible

# For convenience...
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

export KUBECONFIG=/etc/kubernetes/admin.conf

# Wait for API
until [[ $(kubectl get endpoints/kube-dns -n kube-system -o=jsonpath='{.subsets[*].addresses[*].ip}') ]]; do sleep 5; echo -n '.'; done
kubectl wait --for condition=Ready --timeout 600s --all --all-namespaces pod
kubectl wait --for condition=Available --timeout 600s --all-namespaces --all deployment

kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule- || true
