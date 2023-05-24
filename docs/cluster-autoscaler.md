# Cluster Autoscaler on Cluster API

The cluster autoscaler on Cluster API uses the cluster-api project to manage the provisioning and de-provisioning of nodes within a Kubernetes cluster.

It will help in managing the workloads effectively. When load will be high then new nodes will be scaled and if load is low then nodes will be deleted.

# Technical implementation

Idea is to add the cluster-auto scaler ultility by deploying helm chart with image `us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v1.20.0` in `kube-system` namespace of management cluster.
There will be no need to set replicas for machinedeployments. Minimum and maximum count for nodes of cluster will be set, so that it can be scale in and out on basis of conditions like node or unhealthy

# How to test it

After enabling cluster-autoscaler
    Load can be increased on workoad cluster , to check it scale up more nodes
    Load can be decreased on workload cluster, to check it scale down the existing node.