---
title: Scale up/down a workload cluster
sidebar_position: 5
---

## Overview
You can add or remove compute capacity for your cluster workloads by creating or removing Machines. A Machine expresses intent to have a Node with a defined form factor.


## Steps

In order to scale up/down a workload cluster, follow the below steps.

### Prepare environment files

The environment values are defined into `environment-values/workload-clusters/my-workload-cluster/values.yaml`.

Under `cluster:` definition you can scale in or out the control plane or workers by make adjustments with desired number of nodes on:
 
```yaml
cluster:                                                        cluster:
  control_plane_replicas: 1                                   |   control_plane_replicas: 3
  machine_deployments:                                            machine_deployments:
    md0:                                                            md0:
      replicas: 1                                             |       replicas: 2

```
### Apply changes to workload cluster

 ```shell
./apply-workload-cluster.sh environment-values/workload-clusters/my-workload-cluster
 ```

## Example

* Scale-out a workload cluster.

* Initial state (1 control plane and 1 worker):

```shell
kubectl get nodes -o wide
NAME                                             STATUS   ROLES                       AGE     VERSION          INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
first-workload-cluster-cp-6b7c7c5432-ftx4c       Ready    control-plane,etcd,master   25h     v1.26.9+rke2r1   192.168.129.171   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1
first-workload-cluster-md-md0-efa450d0ad-znfn4   Ready    <none>                      3h29m   v1.26.9+rke2r1   192.168.128.122   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1

```
* Modify the number of replicas into the `values.yaml` file and apply the configuration based on the previous steps.

```yaml
cluster:                      
  control_plane_replicas: 1       
  machine_deployments:            
    md0:                          
      replicas: 2
```

Then:

```
./apply-workload-cluster.sh environment-values/workload-clusters/first-workload-cluster

```
* Wait until the new configuration is applied.

```shell
$ kubectl get nodes -o wide
NAME                                             STATUS   ROLES                       AGE     VERSION          INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
first-workload-cluster-cp-6b7c7c5432-ftx4c       Ready    control-plane,etcd,master   26h     v1.26.9+rke2r1   192.168.129.171   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1
first-workload-cluster-md-md0-efa450d0ad-znfn4   Ready    <none>                      3h51m   v1.26.9+rke2r1   192.168.128.122   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1
first-workload-cluster-md-md0-efa450d0ad-r6d7c   Ready    <none>                      59s     v1.26.9+rke2r1   192.168.129.221   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1

```

* Scale in a workload cluster.

* Initial state (1 control plane and 2 workers):

```shell
kubectl get nodes -o wide
NAME                                             STATUS   ROLES                       AGE     VERSION          INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
first-workload-cluster-cp-6b7c7c5432-ftx4c       Ready    control-plane,etcd,master   26h     v1.26.9+rke2r1   192.168.129.171   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1
first-workload-cluster-md-md0-efa450d0ad-znfn4   Ready    <none>                      3h51m   v1.26.9+rke2r1   192.168.128.122   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1
first-workload-cluster-md-md0-efa450d0ad-r6d7c   Ready    <none>                      59s     v1.26.9+rke2r1   192.168.129.221   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1

```

* Modify the number of replicas into the `values.yaml` file and apply the configuration based on the previous steps.

```yaml
cluster:                      
  control_plane_replicas: 1       
  machine_deployments:            
    md0:                          
      replicas: 1
```

Then:

```
./apply-workload-cluster.sh environment-values/workload-clusters/first-workload-cluster

```
* Wait until the new configuration is applied.

```shell
$ kubectl get nodes -o wide
NAME                                             STATUS   ROLES                       AGE     VERSION          INTERNAL-IP       EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
first-workload-cluster-cp-6b7c7c5432-ftx4c       Ready    control-plane,etcd,master   27h     v1.26.9+rke2r1   192.168.129.171   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1
first-workload-cluster-md-md0-efa450d0ad-znfn4   Ready    <none>                      4h      v1.26.9+rke2r1   192.168.128.122   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1
first-workload-cluster-md-md0-efa450d0ad-r6d7c   Ready,SchedulingDisabled   <none>    9m      v1.26.9+rke2r1   192.168.129.221   <none>        Ubuntu 22.04.3 LTS   5.15.0-87-generic   containerd://1.7.3-k3s1

```

