---
title: Addition of workload clusters
sidebar_label: Workload Cluster(s) Addition
sidebar_position: 1
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

This procedure explains the addition of a new workload cluster, assuming the management cluster is already up and running. This procedure can be used to create multiple workload clusters based on OpenStack or Metal3 infrastructure providers.

## Prerequisite

### Workload Cluster on OpenStack VMs

**Workload tenant minimal quotas** (to deploy a single workload clusters with 3 replicas). If the tenant is shared with the management cluster, the tenant quotas need to be adapted in regard to the workload needs. If a quota is not mentioned, it means that the default value is enough (no interest to modify it).

- instances (10: default value) - this default can be changed to scale or deploy multiple workload clusters. The usual minimal instances number is 5 (3 control nodes + 2 worker nodes)
- volumes (20) - depends on user Persistent Volume Claims (PVC) number and instances number. It should be larger than the number of instances + 3 (control volumes) + number of user PVC
- gigabytes (2000) - depends on the number of instances and workload PVC sizes
- cores (64) - 64 vCPU or more, depends on the flavors used
- RAM (128000) - 128GB or more, depending on the flavors used
- networks (10: default value) - if numerous different networks are used on pods with Multus, it can be useful to increase this value.
- ports (50: default value) - if numerous workers with Multus are used, it can be useful to increase this value.

:::note
If workload cluster is to be deployed on OpenStack:
Workload cluster worker flavor examples: B1.xlarge, C2.large, C1.large
Workload cluster master flavor examples: B1.large, C2.medium, C1.medium
:::

### Workload Cluster on Bare-Metal Servers

#### Infrastructure requirements for Workload Cluster on bare-metal

In order to deploy a minimal workload cluster (no HA) on bare-metal servers, we need a bare-metal server, acting as K8s controller and K8s worker. For HA workload cluster, at least three servers are required. The Bare-Metal node should to be compliant with supported hardware catalog. Each server with controller (master), worker and storage (Longhorn) roles requires the following minimal resources:

 - 24 CPU cores (48 vCPU with HT)
 - 64GB RAM
 - 240GB flash boot disk (SSD)
 - 2x Dual 25Gbps NIC
 - Additional dedicated storage device (SSD recommended) if Longhorn is activated on the node
 - Additional Dual 25Gbps NIC is requested for SRIOV worker with dual socket

The same network prerequisites are required than for deploying a management cluster on Bare-Metal, please refer to the [prerequisite section](../Install/prerequisites.md).

## Installation Steps

To create a new workload cluster, follow the below steps.

### Prepare environment files

From bootstrap VM, all the commands need to be run from the `my-deployment/sylva-core/` directory (where the `sylva-virt-docker-stable.repos.tech.orange/otc-caas:0.2.1-mvp` OTC-CaaS release container contents was expanded). <br/>
What's interesting vs. the management cluster guide, is that for workload clusters we can select out of multiple k8s versions, as we support today v1.24, v1.25 or v1.26. <br/>

#### Prepare `values.yaml`

Sample values files for workload cluster are being generated using the same `otc-caas-select.sh` script, under `environment-values/workload-clusters/<workload cluster name>` (where `<workload cluster name>` is provided with script's `--name` parameter; or the default `environment-values/workload-clusters/test-workload-cluster` location, if `--name` parameter is skipped). 
This would again create values.yaml and secrets.yaml files like for the management cluster (only if they don't already exist), where you'll need to define your deployment parameters.
We have slightly more options available for workload clusters selection:

```shell
$ ./otc-caas-select.sh
Usage: ./otc-caas-select.sh [options]

Options:
  --infra <openstack|baremetal>: The infrastructure flavor.
  --cluster-type <management|workload>: The type of cluster to create.
  --k8s-version <v1.24|v1.25|v1.26>: The version of the workload cluster.
  --name <''>: The name of the workload cluster.
```

Use this script depending on the target infrastructure used for hosting the workload cluster:

<Tabs groupId="install-tabs">
<TabItem value="openstack" label='Workload Cluster on OpenStack VMs'>

```shell
# For workload cluster on OpenStack VMs
$ ./otc-caas-select.sh  --infra openstack --cluster-type workload --k8s-version v1.25 --name my-k8s-v1-25-vm-cluster
```
which would return
```shell
Proper environment-values for OTC-CaaS workload cluster on openstack infrastructure were provided in the ./environment-values/workload-clusters/my-k8s-v1-25-vm-cluster directory.
If needed, adjust the contents of your values.yaml and secrets.yaml, and run ./apply-workload-cluster.sh ./environment-values/workload-clusters/my-k8s-v1-25-vm-cluster.
```

:::info Enable BGPaaS unit (Optional)

In order to enable the BGPaaS unit we need to add the following lines in `values.yaml` under the `units` sections:

```yaml
units:
  capo-contrail-bgpaas:
    enabled: true
    helmrelease_spec:
      values:
        conf:
          env:
            API_VERSION_HEATSTACK: 'v1'
            DEFAULT_PORT: '0'
            DEFAULT_ASN: '64512'
```
You can customize the DEFAULT_ASN as per your requirements.
:::

</TabItem>
<TabItem value="baremetal" label='Workload Cluster on Baremetal Servers'>

```shell
# For workload cluster on baremetal servers
$ ./otc-caas-select.sh  --infra baremetal --cluster-type workload --k8s-version v1.25 --name my-k8s-v1-25-bm-cluster
```

</TabItem>
</Tabs>

This `values.yaml` file requires some adaptations to match your environment.

:::note
Choose the directory name wisely as the name and namespace of the workload cluster will be inherited from the directory name itself.
:::

### Prepare `secrets.yaml`

You also need to adapt the secrets in this location returned by the `otc-caas-select.sh` script, according to your environment.

:::note
If the workload cluster is hosted on OpenStack infrastructure, it will use the same credentials as management cluster by default. If you intent to use another tenant for workload cluster, you should provide the credentials in clouds_yaml section of the secret (using the same values as in the `clouds.yaml` file.)
:::

### Trigger OTC-CaaS workload cluster deployment

:::note
For workload cluster deployed on baremetal, we need to increase the reconcile timeout value as node introspection and provisioning takes time
:::

```shell
# workload cluster on OpenStack VMs
$ ./apply-workload-cluster.sh ./environment-values/workload-clusters/my-k8s-v1-25-vm-cluster

# workload cluster on baremetal
$ RECONCILE_TIMEOUT=2h ./apply-workload-cluster.sh ./environment-values/workload-clusters/my-k8s-v1-25-bm-cluster
```

## Tips

:::tip 1. install multiple workload clusters
You can call the `otc-caas-select.sh` with the `--cluster-type workload` and `--name` options multiple times, creating kustomize directories _ready_ (you still need to figure out the values and secrets, of course - see above) to be used for deploying multiple workload clusters.
```shell
$ ./otc-caas-select.sh  --infra openstack --cluster-type workload --k8s-version v1.25 --name my-cluster1
$ ./otc-caas-select.sh  --infra openstack --cluster-type workload --k8s-version v1.24 --name my-cluster2
# then fill in values.yaml and secrets.yaml
# and deploy the workload clusters
$ ./apply-workload-cluster.sh ./environment-values/workload-clusters/my-cluster1
$ ./apply-workload-cluster.sh ./environment-values/workload-clusters/my-cluster2
```
:::


