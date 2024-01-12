# Sylva implementation for Longhorn disk configuration

## Need for declarative Longhorn settings and Sylva context

According to the [documentation](https://longhorn.io/docs/1.5.1/advanced-resources/default-disk-and-node-config/#customizing-default-disks-for-new-nodes) for the [latest release](https://github.com/longhorn/longhorn/releases), depending on whether a node’s label `node.longhorn.io/create-default-disk: 'config'` is present, Longhorn CSI will check for the `node.longhorn.io/default-disks-config` annotation and create default disks according to it. <br/>

Starting with its `v0.2.0` version, the [`cluster-api-provider-rke2`](https://github.com/rancher-sandbox/cluster-api-provider-rke2), aka `CABPR`, supports injecting node annotations via `RKE2ControlPlane.spec.agentConfig.nodeAnnotations` for control-plane nodes (for worker nodes the `RKE2ConfigTemplate.spec.template.spec.agentConfig.nodeAnnotations` is not effective, but is being worked-around within [`sylva-capi-cluster`](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster according to https://gitlab.com/sylva-projects/sylva-core/-/issues/417#note_1668330146) on top of the existent support for injecting node labels, through `RKE2ControlPlane.spec.agentConfig.nodeLabels` and `RKE2ConfigTemplate.spec.template.spec.agentConfig.nodeLabels`. All this is made available by `sylva-units` (through [`sylva-capi-cluster`](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster)) chart values like:

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
