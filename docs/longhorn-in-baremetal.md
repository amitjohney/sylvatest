# Sylva implementation for Longhorn disk configuration

## Need for declarative Longhorn settings and Sylva context

According to the [documentation](https://longhorn.io/docs/1.5.1/advanced-resources/default-disk-and-node-config/#customizing-default-disks-for-new-nodes) for the [latest release](https://github.com/longhorn/longhorn/releases), depending on whether a node’s label `node.longhorn.io/create-default-disk: 'config'` is present, Longhorn CSI will check for the `node.longhorn.io/default-disks-config` annotation and create default disks according to it. <br/>

Starting with its `v0.2.0` version, the [`cluster-api-provider-rke2`](https://github.com/rancher-sandbox/cluster-api-provider-rke2), aka `CABPR`, supports injecting node annotations via `RKE2ControlPlane.spec.agentConfig.nodeAnnotations` for control-plane nodes (for worker nodes the `RKE2ConfigTemplate.spec.template.spec.agentConfig.nodeAnnotations` is not effective, but is being worked-around within [`sylva-capi-cluster`](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster) according to https://gitlab.com/sylva-projects/sylva-core/-/issues/417#note_1668330146) on top of the existent support for injecting node labels, through `RKE2ControlPlane.spec.agentConfig.nodeLabels` and `RKE2ConfigTemplate.spec.template.spec.agentConfig.nodeLabels`. All this is made available by `sylva-units` (through [`sylva-capi-cluster`](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster)) chart values like:

```yaml

cluster:
  rke2:
    nodeLabels:
      node.longhorn.io/create-default-disk: "config"

  control_plane:
    rke2:
      nodeLabels:
        node.longhorn.io/create-default-disk: "config"

  machine_deployment_default:
    rke2:
      nodeLabels:
        node.longhorn.io/create-default-disk: "config"

  machine_deployments:
    md0:
      rke2:
        nodeLabels:
          node.longhorn.io/create-default-disk: "config"
```

```yaml

cluster:
  rke2:
    nodeAnnotations:
      node.longhorn.io/default-node-tags: '["fast","all-nodes"]'

  control_plane:
    rke2:
      nodeAnnotations:
        node.longhorn.io/default-node-tags: '["fast","all-cp"]'

  machine_deployment_default:
    rke2:
      nodeAnnotations:
        node.longhorn.io/default-node-tags: '["very-fast","all-md"]'
        node.longhorn.io/create-default-disk: "config"

  machine_deployments:
    md0:
      rke2:
        nodeAnnotations:
          node.longhorn.io/default-node-tags: '["very-fast","md-specifc"]'

```

## How to define baremetal server disk for Longhorn persistent storage

We need the ability to specify which disks are used for Longhorn _on a per-server basis for baremetal servers_, because they may have a different hardware topology. This per-node granularity is critical to have, because experience has proven that it's not reasonable to expect all nodes in a given group (control nodes, or workers of a given MachineDeployment) would have same disk hardware or PCI topology.

To provide this, we've introduced a special annotation `sylvaproject.org/default-longhorn-disks-config=<customized default disks>` set **on BMH resources**, that uses the value format of the `node.longhorn.io/default-disks-config=<customized default disks>` node annotation, defined by [Longhorn default disks and node configuration](https://github.com/longhorn/longhorn/blob/master/enhancements/20200319-default-disks-and-node-configuration.md#design). With this single BMH annotation we're:

1) mounting the disks for Longhorn following this convention:

    - mount `/dev/sde` at `/var/longhorn/disks/sde`
    - mount `/dev/disk/by-path/pci-0000:18:00.0-scsi-0:3:110:0` at `/var/longhorn/disks/disk_by-path_pci-0000:18:00.0-scsi-0:3:110:0`
as Longhorn does not take of that _at all_. We do this inside cloud-init configuration provided by [`sylva-capi-cluster`](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster).

2) annotating the node created by the Machine consuming the BareMetalHost with `node.longhorn.io/default-disks-config=<customized default disks>`. **For this reason, it's very important to use the `"allowScheduling":true` inside the `sylvaproject.org/default-longhorn-disks-config` annotation value, as this parameter would indicate to Longhorn manager whether the user enabled/disabled replica scheduling for the node.**

3) label the node created by the Machine consuming the BareMetalHost with `node.longhorn.io/create-default-disk: 'config'`.

To have the implementation picture in mind, we propagate this individual BMH metadata to consumer CAPI machine (to achieve per-node granularity) for both disk configuration and setting annotations (and labels in case of CAPBK, where the ability to provide labels to nodes declaratively is not natively provided by the bootstrap provider) inside cloud-init, we need to rely on the "BMH -\> Metal3 metadata -\> ds.metadata" channel and set the node annotation based on the said BMH annotation running a `kubectl annotate $(hostname) node.longhorn.io/default-disks-config=<customized default disks>` command on each node.
This workflow is:

- use the following `sylva-units` values to annotate the BMH:

```yaml

cluster:
  baremetal_hosts:
    my-bmh-foo:
      bmh_metadata:
        annotations:
          sylvaproject.org/default-longhorn-disks-config: '[ { "path":"/var/longhorn/disks/disk_by-path_pci-0000:18:00.0-scsi-0:3:111:0", "allowScheduling":true, "storageReserved":0, "tags":[ "ssd", "fast" ] }]'

```

- which allows `Metal3DataTemplate.spec.metaData.fromAnnotations` to read it based on:

```yaml

metaData:
  :
  fromAnnotations:
  - key: sylva_longhorn_disks
    object: baremetalhost
    annotation: sylvaproject.org/default-longhorn-disks-config
  {{- end }}

```

- to further use it inside cloud-init for both CP and MD nodes, with something like:

```yaml

postRKE2Commands:
  {{- if .Values.enable_longhorn }}
  - /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml annotate node $(hostname) {{ printf "%s=%s" "node.longhorn.io/default-disks-config" `{{ ds.meta_data.sylva_longhorn_disks }}` }}

```

- which will result in a bootstrapped node like:

```yaml

apiVersion: v1
kind: Node
metadata:
  annotations:
    node.longhorn.io/default-disks-config: '[{"path":"/var/longhorn/disks/disk_by-path_pci-0000:18:00.0-scsi-0:3:111:0",
      "storageReserved":0, "allowScheduling":true, "tags":[ "ssd", "fast" ]}]'
    :
    rke2.io/node-args: '["server","--cluster-cidr","100.72.0.0/16","--cni","calico","--kubelet-arg","anonymous-auth=false","--kubelet-arg","provider-id=metal3://sylva-system/mgmt-cluster-my-bmh-foo/mgmt-cluster-cp-056108e4c3-5b9sj","--node-label","--node-label","node.longhorn.io/create-default-disk=config","--profile","cis-1.23","--service-cidr","100.73.0.0/16","--tls-san","172.18.0.2","--tls-san","192.168.100.2","--token","********"]'
  labels:
    :
    node.longhorn.io/create-default-disk: config

```

```shell

root@gmt-cluster-my-bmh-foo:/# lsblk
NAME  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
vda   252:0    0   50G  0 disk
├─vda1
│     252:1    0  550M  0 part /boot/efi
├─vda2
│     252:2    0    8M  0 part
├─vda3
│     252:3    0 49.4G  0 part /
└─vda4
      252:4    0   65M  0 part
vdb   252:16   0   50G  0 disk
vdc   252:32   0   50G  0 disk /var/longhorn/disks/disk_by-path_pci-0000:18:00.0-scsi-0:3:111:0
root@gmt-cluster-my-bmh-foo:/#

```

> **_IMPORTANT NOTICE:_** A prerequisite for having the ability to use this BMH annotation to define Longhorn disk consumption is the usage of:

```yaml

cluster:
  enable_longhorn: true

```

> **_IMPORTANT NOTICE:_** With this we've also dropped the support for the `node.longhorn.io/create-default-disk: true` node label, and it cannot be used anymore by stack operators.
