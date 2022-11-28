# Grab some info in case of failure, essentially usefull to troubleshoot CI, fell free to add your own commands while troubleshooting

echo "Docker containers"
docker ps

echo "System info"
free -h
df -h || true

echo "Flux kustomize-controller  logs in bootstrap cluster"
kubectl logs -n flux-system -l app=kustomize-controller

echo "CAPI logs in bootstrap cluster"
kubectl logs -n capi-system -l control-plane=controller-manager

echo "CAPD logs in bootstrap cluster"
kubectl logs -n capd-system -l control-plane=controller-manager

if [[ -f $BASE_DIR/management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${KUBECONFIG:-$BASE_DIR/management-cluster-kubeconfig}

    echo "Get nodes in management cluster"
    kubectl --request-timeout=3s get nodes

    echo "Get pods in management cluster"
    kubectl --request-timeout=3s get pods -A -o yaml
fi

echo "Dump node logs"
docker ps -q -f name=management-cluster-control-plane* | xargs -I % -r docker exec % journalctl -e

