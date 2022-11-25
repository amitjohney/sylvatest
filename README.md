# cluster-init

This project enables to bootstrap a ClusterAPI management cluster in a declarative way, using Flux to keep some kustomization & Helm releases in sync with a git repo, using the following workflow:

- Use `kind` (or `kubeadm init` on a disposable VM) to build a temporary bootstrap cluster
- Install Flux on that cluster
- Use a Flux HelmRelease to control the deployment of various Flux Kustomizations that will successively deploy cluster-api & infrastructure components using Flux Kustomization
- Other dependent Kustomizations will also be deployed to install management cluster definitions, that will be used by cluster-api to deploy the management cluster
- Once the management cluster is deployed, Flux will be installed in it, as well as the main HelmRelease that will deploy again cluster-api & infrastructure components in the management cluster
- Management cluster definitions are moved (aka. pivoted) to management cluster, that will become independent and self-managed
- At this stage, bootstrap cluster can be deleted

We'll then be able to install resources in the management cluster (like rancher) and workload clusters definitions,

For now, we support and test in CI Docker (capd) and Openstack (capo) infrastructure providers, using kuebadm (cabpk) and rke2 (cabpr) bootstrap providers. Hopefully there'll be more providers soon ;)

# Repository structure

- [kustomize-components](kustomize-components) contains the manifests used to deploy various cluster-api & infrastructure components, they will be deployed as flux kustomizations, and must contain some kustomizations.yaml for that purpose. Note that such components could also live in external git repositories.
- [charts/telco-cloud-init](charts/telco-cloud-init/README.md) is the main helm chart that controls the installation of selected/relevant flux kustomizations in the cluster, depending on the context (bootstrap, management, workload cluster) and the type of cluster-api infrastucture/bootstrap providers that are used.
- [environment-values](environment-values) contains user-provided values to control the deployment of the cluster. They attempt to provide default parameters for various deployment scenarios, but may be modified to adapt to deployment scenarios. They will be rendered locally using kustomize tool to generate values (and secrets for security-sensitive data) that will control the behaviour of the helm chart.
- [tools](tools) contains some helper scripts for the bootstrap script, as well as some other utilities
- [bootstrap.sh](bootstrap.sh) is the entry-point of the project, it installs flux, user-config, and telco-cloud-init chart in the bootstrap cluster, and follows the deployment of the cluster.

# How it works

As explained above, all component manifests (cluster-api & infrastructure components, cluster definitions, jobs...) are controlled by Flux Kustomizations managed by the telco-cloud-init Helm chart. In the bootstrap process, this Helm chart itself is deployed as a Flux helmrelease, that will use following values:
- default [`values.yaml`](charts/telco-cloud-init/values.yaml) that contains global defaults
- [`bootstrap.values.yaml`](charts/telco-cloud-init/bootstrap.values.yaml) overloads defaults with some components that are specific to the bootstrap (copy config to management cluster, install Flux and telco-cloud-init chart on it, pivot)
- environment-values that are provided by the user, and saved in management-cluster-values and management-cluster-secrets. These values will be copied into the management cluster by the management-cluster-configs component.

The instantiation of a Flux HelmRelease for this Helm chart in the bootstrap cluster is performed by [a specific kustomization](kustomize-components/telco-cloud-init/bootstrap/kustomization.yaml) that passes values listed above. When the HelmRelease will be installed in the management cluster, it'll use [another variant](kustomize-components/telco-cloud-init/management-before-pivot/kustomization.yaml) of this HelmRelease that does not include `bootstrap.values.yaml` values. This will create all components on the management cluster, except the cluster definitions (otherwise it would start creating a new cluster again), these definitions will be created by the pivot job that will move definitions from bootstrap to management cluster, at the end of the process, the pivot will enable the management cluster definition (a kustomisation) in the management cluster, to keep it in sync with its git definition.

This way, after pivot, we end up with a management cluster managed by cluster-api (from an infrastructure point of view) and by the telco-cloud-init HelmRelease (controlled by default `values.yaml` plus what is overloaded by user-provided environment-values).

Note that the bootstrap/pivot process is not mandatory: the provided chart can also be used to deploy all management cluster components in an existing cluster. In that case, the management cluster lifecycle won't be managed by cluster-api.

# How to use

## Deploying clusters in docker using CAPD

Event if it is not representative of any real-life deployment use-case, running clusters in docker is useful to enable the testing of lifecycle management of clusters without any infrastructure requirement.

It can be used to test that stack on a laptop or in [gitlab-ci](.gitlab-ci.yml). You just have to install kubectl and [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation), and clone this project.

Then you'll have to create a kind cluster with access to docker socket (there is also [a script that is provided](tools/kind-with-registry.sh) to do that, and more):
```shell
cat <<EOF | kind create cluster --name capd --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
EOF
```

And provide your gitlab username and a gitlab token with read access to repository and registry.
```
GITLAB_USER=your_name GITLAB_TOKEN=glpat-XXXXXXX ./bootstrap.sh environment-values/rke2-capd
```

In the above command, we're just instructing the bootstrap script to use sample configuration provided in [environment-values/rke2-capd/](environment-values/rke2-capd/) directory. You will probably want to modify these values to adapt to your needs and environment (for example, you may want to change the management-cluster kustomisation path in [values.yaml](environment-values/rke2-capd/values.yaml)).

You can also deploy cluster using the kubeadm infrastructure provider by using the corresponding `environment-values/kubeadm-capd` directory

For now it will only deploy a single-node RKE2 cluster, but it's a starting point to add more stuff (rancher, [capi-rancher-import](https://gitlab.com/t6306/components/capi-rancher-import), workload-clusters...)

## Deploying clusters in openstack

:::note
For environments where an automatic creation of a workload cluster and its importing in Rancher server (deployed in the management cluster) workflow is triggered (like for _kubeadm-capo_) we have some traffic flow requirements:
1. since the [workload cluster's /etc/resolv.conf](./kustomize-components/cluster-manifests/kubeadm-capo/orange-falcon-single-node/kustomization.yaml#L99-115) would be configured with the management cluster's k8s-gateway LoadBalancer service External IP (set by the `KUBE_VIP_IP` var of management cluster) to allow for resolving the Rancher FQDN, we will need to also permit DNS traffic (UDP port 53) for the management cluster ingress direction. <br/>
2. since the workload cluster's [cattle-cluster-agent](https://docs.ranchermanager.rancher.io/v2.6/how-to-guides/new-user-guides/launch-kubernetes-with-rancher/about-rancher-agents#cattle-cluster-agent) will conenct to the Rancher server FQDN (Ingress service External IP set by the `KUBE_VIP_IP` var of management cluster), we will need to also permit TLS traffic (TCP port 443) for the management cluster ingress direction, as per [Rancher downstream nodes port requirements](https://docs.ranchermanager.rancher.io/v2.6/getting-started/installation-and-upgrade/installation-requirements/port-requirements#downstream-kubernetes-cluster-nodes). Such traffic flow would also be needed for connecting to Rancher webUI. <br/>
If we are deploying both the management cluster and the workload cluster on the same Neutron network, like having all nodes attached to the same VLAN-based Provider Network, then these flows are permitted by default due to the fact that traffic internal to a Neutron network is not subject to Security Group-based filtering. <br/>

However, if the management cluster and the workload cluster nodes would not share the same network (like using different Provider Networks), we can meet these requirements by setting the proper rules for the `default` SG of the OpenStack tenant in which the management cluster is deployed, since in the manifest of the _kubeadm-capo_ management cluster we're adding this [pre-existing SG to the spec of an OpenStackMachineTemplate](./kustomize-components/cluster-manifests/kubeadm-capo/base/management-cluster.yaml#L100-101).
To provide these rule in OpenStack, the tenant admin can run:

```console
openstack security group rule create --ethertype IPv4 --ingress --protocol udp --dst-port 53 --remote-ip 0.0.0.0/0 
--description "For k8s-gateway DNS resolving of Rancher" default
openstack security group rule create --ethertype IPv4 --ingress --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0 --description "For Rancher importing" default
```

:::

### Using kind

The workflow is quite similar to previous one with docker, you'll only have to provide different variables:

Install kubectl and [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation), and clone this project.

Create a kind cluster and use it as default kubectl context:
```
kind create cluster --name bootstrap
```

Provided that you work on Orange's Falcon platform, you need to provide (at least) your ssh-key name in [values.yaml](environment-values/kubeadm-capo/values.yaml) and openstack credentials that will be used by capo in [infra-secrets.yaml](environment-values/kubeadm-capo/infra-secrets.yaml).

Once this is done, you just need to run the bootstrap script:
```shell
GITLAB_USER=your_name GITLAB_TOKEN=glpat-XXXXXXX ./bootstrap.sh environment-values/kubeadm-capo
```

> **_NOTE FOR DEVELOPPERS:_**
> If you intent to contribute to this project, you will probably want to avoid committing values and secrets related to your environment. To that extent, you can create your own copy of values directory that will be gitignored:
> ```shell
> cp -a environment-values/kubeadm-capo environment-values/my-capo-env
> # Fill my-capo-env with your local values, then
> ./bootstrap.sh environment-values/my-capo-env
> ```

### Using a disposable openstack VM

Note: this section and associated scripts have not been updated to reflect recent changes, they are not relevant any more.

Create your own (gitignored) copy of bootstrap-data used for cloud-init, and change (at least) OS_PROJECT_NAME, OS_USERNAME, OS_PASSWORD and SSH_KEY_NAME to match your environment

```shell
cp bootstrap-data-sample bootstrap-data
```

Then you can boot the bootstrap VM:

```shell
openstack --os-cloud falcon server create --image capo-ubuntu-2004-kube-v1.23.6-calico-3.23.1 --boot-from-volume 20 --flavor m1.medium --key-name YOUR_SSH_KEY_NAME --user-data my-bootstrap-data --network NIS_20 bootstrap
```

Once cloud-init fires up, you If everything runs properly, you should be able  to retrieve management cluster kubeconfig at the end of bootstrap server cloud-init script:

```shell
ssh ubuntu@[BOOTSTRAP_VM_IP] tail -f /home/ubuntu/bootstrap/bootstrap.log
```

Once bootstrap process completes, you can retrieve management cluster kubeconfig file:

```shell
scp ubuntu@[BOOTSTRAP_VM_IP]:~/bootstrap/[CLUSTER_NAME]-kubeconfig .
```

Then you can delete bootstrap VM:
```shell
openstack --os-cloud falcon server delete bootstrap
```

### Installation without bootstrap, on a pre-existing cluster

The `apply.sh` script can be used to deploy the stack on a pre-existing cluster
without relying on the bootstrap stage at all.

Assuming that the current `kubectl` context points to the target cluster and
that the environment values have been prepared under some `environment-values/xxxxx` directory,
and that the `GITLAB_USER` and `GITLAB_TOKEN` environement variables are suitably set,
the following will deploy the stack:

```
./apply.sh <path/to/environment>
```

## Tips & Troubleshooting

### Generic

You can see detailed status information on management cluster provisioning with:

```shell
clusterctl describe cluster management-cluster --show-conditions all
```
### When bootstraping from an OpenStack VM with userdata

You can ssh to bootstrap and cluster VMs using provided ssh key with ubuntu user

`/var/log/cloud-init-output.log` and `~/bootstrap/bootstrap.log` are good first starting points

You can follow flux sync using `kubectl -n flux-system get kustomizations.kustomize.toolkit.fluxcd.io`

And check for management cluster control plane using `kubectl get kubeadmcontrolplane`

Note that after pivot, these commands won't return anything on bootstrap cluster, as the resources we'll have been moved to management cluster.

You can retrieve management cluster kubeconfig in `~/bootstrap/management-cluster-kubeconfig`

### Working directly on the management cluster

Once the bootstrap phase is done, and the pivot is done, the management
cluster can be updated with:

```
./apply.sh <your-environment-name>
```

This assumes that the required environment variables are set.

## Cleaning things up

One limitation of this approach is that management cluster can not delete himself properly, as it will shoot itself in the foot at some point.
[cleanup.sh](cleanup.sh) is provided to help cleaning the resources created by capo. Use it at your own risk, especially for the last item that deletes all unattached volumes.

# Possible next steps (among others...)

- Create a gitlab project & ci script to build and push capo-images
- A heat stack to bootstrap the VM?
- Use octavia instead of FIP (and use 3 control nodes) when it will be more reliable
- Investigate MachineHealthChecks and make sure that they properly manage FAILED and SHUTDOWN VMs
