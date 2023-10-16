# Sylva implementation for Longhorn disk configuration

## Need for declarative Longhorn settings and Sylva context

According to the [documentation](https://longhorn.io/docs/1.5.1/advanced-resources/default-disk-and-node-config/#customizing-default-disks-for-new-nodes) for the [latest release](https://github.com/longhorn/longhorn/releases), depending on whether a node’s label `node.longhorn.io/create-default-disk: 'config'` is present, Longhorn CSI will check for the `node.longhorn.io/default-disks-config` annotation and create default disks according to it. <br/>

The [`rke2-server` binary options](https://docs.rke2.io/reference/server_config) only cover node labels and node taints, but not node annotations, that is why for now the [`cluster-api-provider-rke2`](https://github.com/rancher-sandbox/cluster-api-provider-rke2), aka `CABPR`, (in its `v0.1.1`) is not able to provide a way for setting node annotations (tracked in [upstream issue #155](https://github.com/rancher-sandbox/cluster-api-provider-rke2/issues/155)). <br/>
It does however support injecting node labels through `RKE2ControlPlane.spec.agentConfig.nodeLabels` and `RKE2ConfigTemplate.spec.template.spec.agentConfig.nodeLabels`, which `sylva-units` (through [`sylva-capi-cluster`](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster)) can deliver. It does so for chart values like:

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

## How we worked around it

### The idea

Since [Kyverno](https://kyverno.io/) is the policy engine present in Sylva and our need here is to have declarative tooling for transforming a K8s resource such as the node in order to comply with Longhorn expected configuration, the option to introduce a Kyverno policy with [mutate rule](https://kyverno.io/docs/writing-policies/mutate/) surfaced. <br/>
At a high level, this mutate policy would need to:

- match K8s node resources, conditioned by the presence of a specific label;

- copy the content of a label into a node annotation.

### The challenges

Simply passing any label as an annotation was not going to work for us, since the Longhorn annotations values expect data in JSON format, while [K8s labels format](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set) has strict requirements, like:

```markdown

Valid label value:
- must be 63 characters or less (can be empty),
- unless empty, must begin and end with an alphanumeric character ([a-z0-9A-Z]),
- could contain dashes (-), underscores (_), dots (.), and alphanumerics between.

```

This meant the labels from which the annotations would have been computed and applied by Kyverno also needed some work to trim (to 63 or lower lengths) and ensure they only contained allowed charactes. For that reason, we decided to expose to Sylva stack users the ability to provide node annotations in the form they'd expect them to appear on the nodes and do some internal shuffling behind the scenes to make it happen, through [`sylva-capi-cluster`](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster). <br/>
It translated to the ability to provide some environment values like:

```yaml

cluster:
  rke2:
    node_annotations:
      node.longhorn.io/default-disks-config: '[ { "path":"/var/lib/longhorn", "allowScheduling":true}, { "name":"fast-ssd-disk", "path":"/mnt/extra", "allowScheduling":false, "storageReserved":10485760, "tags":[ "ssd", "fast" ] }]'
      node.longhorn.io/default-node-tags: '["fast","storage"]'

  control_plane:
    rke2:
      node_annotations:
        :

  machine_deployment_default:
    rke2:
      node_annotations:
        :

  machine_deployments:
    md0:
      rke2:
        node_annotations:
          :

```

and the labels from such `rke2.node_annotations` would be resulted from the base64 encoding of the label value, split in as many segments of 63 chars as necessary, with an index of the segment added to the original label to allow for reconstructing the original base64 string at the destination (Kyverno) end. <br/>
This implied that for such `rke2.node_annotations` inputs we set:

```yaml

  agentConfig:
    nodeLabels:
    - node.longhorn.io/default-disks-config0=WyB7ICJwYXRoIjoiL3Zhci9saWIvbG9uZ2hvcm4iLCAiYWxsb3dTY2hlZHVsaW5
    - node.longhorn.io/default-disks-config1=nIjp0cnVlfSwgeyAibmFtZSI6ImZhc3Qtc3NkLWRpc2siLCAicGF0aCI6Ii9tbn
    - node.longhorn.io/default-disks-config2=QvZXh0cmEiLCAiYWxsb3dTY2hlZHVsaW5nIjpmYWxzZSwgInN0b3JhZ2VSZXNlc
    - node.longhorn.io/default-disks-config3=nZlZCI6MTA0ODU3NjAsICJ0YWdzIjpbICJzc2QiLCAiZmFzdCIgXSB9XQ-x-x
    - node.longhorn.io/default-node-tags=WyJmYXN0Iiwic3RvcmFnZSJd
    - sylva.org/annotate-node-from-label-done-by=a3l2ZXJubw-x-x

```

inside CABPR CRs. <br/>

Another K8s constraint was the fact that "*a valid label must be an empty string or consist of alphanumeric characters, '-', '_' or '.', and must start **and end** with an alphanumeric character*" and in case of base64 there's often [padding with `=` characters](https://en.wikipedia.org/wiki/Base64#Output_padding), that is why before splitting the base64 encoding of the label value in multiple segments of 63 chars (the last segment can be of 63 or less), we needed to also replace `=` with something that would make the label value compliant, and `-x` was the option we went for here. <br/>

So from the above cluster manifests, we reach a state where the created cluster node has labels like:

```yaml

$ kubect get node management-cluster-cp-485bfc7e1e-5b2vs -o yaml | yq .metadata.labels
beta.kubernetes.io/arch: amd64
beta.kubernetes.io/os: linux
kubernetes.io/arch: amd64
kubernetes.io/hostname: management-cluster-cp-485bfc7e1e-5b2vs
kubernetes.io/os: linux
node-role.kubernetes.io/control-plane: "true"
node-role.kubernetes.io/etcd: "true"
node-role.kubernetes.io/master: "true"
node.longhorn.io/create-default-disk: config
node.longhorn.io/default-disks-config0: WyB7ICJwYXRoIjoiL3Zhci9saWIvbG9uZ2hvcm4iLCAiYWxsb3dTY2hlZHVsaW5
node.longhorn.io/default-disks-config1: nIjp0cnVlfSwgeyAibmFtZSI6ImZhc3Qtc3NkLWRpc2siLCAicGF0aCI6Ii9tbn
node.longhorn.io/default-disks-config2: QvZXh0cmEiLCAiYWxsb3dTY2hlZHVsaW5nIjpmYWxzZSwgInN0b3JhZ2VSZXNlc
node.longhorn.io/default-disks-config3: nZlZCI6MTA0ODU3NjAsICJ0YWdzIjpbICJzc2QiLCAiZmFzdCIgXSB9XQ-x-x
node.longhorn.io/default-node-tags: WyJmYXN0Iiwic3RvcmFnZSJd
sylva.org/annotate-node-from-label: "true"    # a label on which we choose to act upon with the mutate rule Kyverno ClusterPolicy
topology.cinder.csi.openstack.org/zone: dev-az
$

```

### The magic of Kyverno

With such information available on the node, it was left only for Kyverno to do its magic. We had to:

1. do for all nodes that have the label `sylva.org/annotate-node-from-label: "true"` applied;

1. get the values for all labels having their keys starting with a particular label key (the original label key set via `rke2.node_annotations` values):

1. join all such label values in this this oder;

1. replace `-x` with `=` to get the original base64 encoded string and base64 decode it, then apply it as as annotation value;

1. rinse and repeat for every `rke2.node_annotations` label key used in `sylva-units` values, for every node labeled `sylva.org/annotate-node-from-label: "true"`. <br/>

This logic is provided by `ClusterPolicy.kyverno.io/annotate-node-from-label-list`, defined in [`annotate-nodes-from-base64-label.yaml`](../kustomize-units/node-annotation-from-label/annotate-nodes-from-base64-label.yaml) inside unit `node-annotation-from-label`.

```shell

$ kubect get --raw /api/v1/nodes/management-cluster-cp-485bfc7e1e-5b2vs | jq | kubectl kyverno jp query "items(metadata.labels, 'key', 'value')[?starts_with(key, 'node.longhorn.io/default-disks-config')][].value"
Reading from terminal input.
Enter input object and hit Ctrl+D.
# items(metadata.labels, 'key', 'value')[?starts_with(key, 'node.longhorn.io/default-disks-config')][].value
[
  "WyB7ICJwYXRoIjoiL3Zhci9saWIvbG9uZ2hvcm4iLCAiYWxsb3dTY2hlZHVsaW5",
  "nIjp0cnVlfSwgeyAibmFtZSI6ImZhc3Qtc3NkLWRpc2siLCAicGF0aCI6Ii9tbn",
  "QvZXh0cmEiLCAiYWxsb3dTY2hlZHVsaW5nIjpmYWxzZSwgInN0b3JhZ2VSZXNlc",
  "nZlZCI6MTA0ODU3NjAsICJ0YWdzIjpbICJzc2QiLCAiZmFzdCIgXSB9XQ-x-x"
]
$

```

> ***Note***: When figuring out the Kyverno's [JMESPath](https://kyverno.io/docs/writing-policies/jmespath/), it can be of help to employ the [jp tool](https://kyverno.io/docs/kyverno-cli/#jp) (used above).
