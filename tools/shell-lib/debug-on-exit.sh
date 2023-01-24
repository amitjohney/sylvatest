# Grab some info in case of failure, essentially usefull to troubleshoot CI, fell free to add your own commands while troubleshooting

function dump_flux_resources() {
    cluster_dir=$1
    echo "Dumping Flux resources to $cluster_dir"
    for kind in gitrepositories helmcharts helmrepositories helmreleases kustomizations ; do
        kubectl get $kind -o wide > $cluster_dir/flux-$kind.summary.txt
        kubectl get $kind -o yaml > $cluster_dir/flux-$kind.yaml
    done
}

echo "Docker containers"
docker ps

echo "System info"
free -h
df -h || true

echo "Performing dump on bootstrap cluster"
kubectl cluster-info dump -A -o yaml --output-directory=bootstrap-cluster-dump

dump_flux_resources bootstrap-cluster-dump

if [[ -f $BASE_DIR/management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${KUBECONFIG:-$BASE_DIR/management-cluster-kubeconfig}

    echo "Get nodes in management cluster"
    kubectl --request-timeout=3s get nodes

    echo "Get pods in management cluster"
    kubectl --request-timeout=3s get pods -A

    echo "Performing dump on management cluster"
    kubectl cluster-info dump -A -o yaml --output-directory=management-cluster-dump

    dump_flux_resources management-cluster-dump
fi

echo "Dump node logs"
docker ps -q -f name=management-cluster-control-plane* | xargs -I % -r docker exec % journalctl -e
