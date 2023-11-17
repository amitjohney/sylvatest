# Grab some info in case of failure, essentially usefull to troubleshoot CI, fell free to add your own commands while troubleshooting

# list of kinds to dump
#
# for some resources, we add the apiGroup because there are resources
# with same names in CAPI and Rancher provisioning.cattle.io/management.cattle.io API groups
# we want the CAPI Cluster ones (e.g. Clusters.*cluster.x-k8s.io) rather than
# the Rancher one (e.g Clusters.provisioning.cattle.io)
additional_resources="
  Namespaces
  HelmReleases
  Kustomizations
  StatefulSets
  Jobs
  CronJobs
  PersistentVolumes
  PersistentVolumeClaims
  ConfigMaps
  Clusters.*cluster.x-k8s.io
  MachineDeployments
  Machines
  KubeadmControlPlanes
  KubeadmConfigTemplates
  KubeadmConfigs
  RKE2ControlPlanes
  RKE2ConfigTemplates
  RKE2Configs
  DockerClusters
  DockerMachineTemplates
  DockerMachines
  VSphereClusters.*cluster.x-k8s.io
  VSphereMachineTemplates.*cluster.x-k8s.io
  VSphereMachines.*cluster.x-k8s.io
  OpenStackClusters
  OpenStackMachineTemplates
  OpenStackMachines
  Metal3Clusters
  Metal3MachineTemplates
  Metal3Machines
  Metal3DataTemplates
  BaremetalHosts
"

function dump_additional_resources() {
    local cluster_dir=$1
    shift
    for cr in $@; do
      echo "Dumping resources $cr in the whole cluster"
      if kubectl api-resources | grep -qi $cr ; then
        base_filename=$cluster_dir/${cr/.\**/}
        kind=${cr/\*/}  # transform the .* used for matching kubectl api-resource, into a plain '.'
                        # (see Clusters.*cluster.x-k8s.io above)

        if [[ $kind == HelmReleases || $kind == Kustomizations ]]; then
            flux get $kind -A > $base_filename.txt
        else
            kubectl get $kind -A -o wide > $base_filename.txt
        fi

        kubectl get $kind -A -o yaml > $base_filename.yaml
      fi
    done
}

echo "Docker containers"
docker ps

echo "System info"
free -h
df -h || true

echo "Performing dump on bootstrap cluster"
kubectl cluster-info dump -A -o yaml --output-directory=bootstrap-cluster-dump

dump_additional_resources bootstrap-cluster-dump $additional_resources

if [[ -f $BASE_DIR/management-cluster-kubeconfig ]]; then
    export KUBECONFIG=${KUBECONFIG:-$BASE_DIR/management-cluster-kubeconfig}

    echo "Get nodes in management cluster"
    kubectl --request-timeout=3s get nodes

    echo "Get pods in management cluster"
    kubectl --request-timeout=3s get pods -A

    echo "Performing dump on management cluster"
    kubectl cluster-info dump -A -o yaml --output-directory=management-cluster-dump

    dump_additional_resources management-cluster-dump $additional_resources
fi

echo "Dump node logs"
docker ps -q -f name=management-cluster-control-plane* | xargs -I % -r docker exec % journalctl -e
