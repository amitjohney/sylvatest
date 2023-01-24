# Capi-bootstrap project

This project provides the tools and configuration to deploy a ClusterAPI management cluster and associated infrastructure in a declarative way, using Flux to keep some Kustomizations & Helm releases in sync with Git repos.

It is build around the sylva-units helm chart that creates flux objects used to deploy various units depending on the capi bootstrap and infrastructure providers that you intend to use.

You can use it to deploy Cluster API and aditionnal units in an existing Kubernetes cluster, or you can use an intermediate temporary/disposable bootstrap cluster that will be used to provision the management cluster using cluster API, which will enable you to manage the lifecycle of the management cluster itself in the future. See [Bootstrap process](#bootstrap-process) for more details on that process.

## Repository structure

- [kustomize-units](kustomize-units) contains the manifests used to deploy various cluster-api & infrastructure units, they will be deployed as flux Kustomizations, and must contain some Kustomizations.yaml for that purpose. Note that such units could also live in external Git repositories.
- [charts/sylva-units](charts/sylva-units/README.md) is the main helm chart that controls the installation of selected/relevant flux Kustomizations in the cluster, as well as HelmReleases, depending on the context (bootstrap, management, workload cluster) and the type of cluster-api infrastructure/bootstrap providers that are used.
- [environment-values](environment-values) contains user-provided values to control the deployment of the cluster. They attempt to provide default parameters for various deployment scenarios, but may be modified to adapt  to deployment scenarios. They will be rendered locally using kustomize tool to generate values (and secrets for security-sensitive data) that will control the behavior of the helm chart.
- [tools](tools) contains some helper scripts for the bootstrap script, as well as some other utilities
- [bootstrap.sh](bootstrap.sh) scripts will bootstrap the management cluster using a temporary cluster as described below.
- [apply.sh](apply.sh) enables to install or update the units of the management cluster. It can be used on a pre-existing cluster installed manually, or on a cluster that has been bootstrapped with this project.

## Bootstrap process

This project enables to bootstrap a ClusterAPI management cluster in a declarative way, using Flux to keep some Kustomization & Helm releases in sync with a Git repo, using the following workflow:

- Use `kind` to build a temporary bootstrap cluster
- Install Flux on that cluster
- Use a Flux HelmRelease to control the deployment of various Flux Kustomizations that will successively deploy cluster-api & infrastructure units
- Other dependent Kustomizations will also be deployed to install management cluster definitions, that will be used by cluster-api to deploy the management cluster
- Once the management cluster is deployed, Flux will be installed in it, as well as the sylva-units HelmRelease that will deploy again cluster-api & infrastructure units in the management cluster
- Management cluster definitions are moved (aka. pivoted) to management cluster, that will become independent and self-managed
- At this stage, bootstrap cluster can be deleted

We'll then be able to install resources in the management cluster (like Rancher) and workload clusters definitions,

For now, we support and test in CI Docker (capd) and OpenStack (capo) infrastructure providers, using kuebadm (cabpk) and rke2 (cabpr) bootstrap providers. Hopefully there'll be more providers soon ;)

## Configuration management

As explained above, all unit manifests (cluster-api & infrastructure units, cluster definitions, jobs...) are controlled by Flux Kustomizations or HelmReleases managed by the sylva-units Helm chart. As this chart produces manifests for all units, it enables to easily share and reuse variables between various parts of the system. For that purpose, it also enables the use of go templates expressions in values, this way various expressions may be used to build values depending on other ones.

This chart can be installed using the helm tool, but we encourage to deploy it using a [flux HelmRelease](https://fluxcd.io/flux/components/helm/helmreleases/). One of the main advantage of this approach is that it enables us to merge several layers of values over the [charts defaults](charts/sylva-units/values.yaml) using kubernetes ConfigMaps and Secrets. All these values are typically created using Kustomizations provided in [environment-values](environment-values) directory. For example, the chart could be deployed with following values:

- [default values](charts/sylva-units/values.yaml) from the chart
- [bootstrap values](charts/sylva-units/bootstrap.values.yaml) that will overloads defaults with some units that are specific to the bootstrap process (copy config to management cluster, install Flux and sylva-units chart on it, pivot)
- various layers of values relative to the deployment context can then be merged over default one, these are typically parameters that are shared inside a company (like an internal repository, or proxy URL). These values can be hosted in external repositories that will be fetched by the kustomize tool. This mechanism enables to efficiently share common values, and help minimizing the amount of parameters that users have to provide.
- finally, user values will provide secrets and parameters that are specific to a deployment

## How to use

### Deploying clusters in Docker using CAPD

Event if it is not representative of any real-life deployment use-case, running clusters in Docker is useful to enable the testing of lifecycle management of clusters without any infrastructure requirement.

It can be used to test that stack on a laptop or in [GitLab-ci](.gitlab-ci.yml). You just have to install kubectl and [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation), and clone this project.

Then you'll have to create a kind cluster with access to Docker socket:

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

As we'll be creating a fair amount of containers, it is recommended to increase the filesystem watcher limit in order to avoid reaching the limit.

 ```shell
 echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
 echo "fs.inotify.max_user_instances = 512" | sudo tee -a /etc/sysctl.conf
 sudo sysctl -p /etc/sysctl.conf
 ```

Create your copy of environment-values, and provide your GitLab username and a GitLab token with read access to repository and registry:

```shell
cp -a environment-values/rke2-capd environment-values/my-rke2-capd
cat <<EOF > environment-values/my-rke2-capd/git-secrets.env
username=your_name
password=glpat-xxxxxxxxxxxxxx
EOF
```

> **_NOTE:_** obviously, the files  `git-secrets.env` are sensitive and are meant to be ignored by Git  (see `.gitignore`). However, for the sake of security, it can be good idea to [secure these files with SOPS](./sops-howto.md) to mitigate the risk of leakage.

(You can also deploy cluster using the kubeadm infrastructure provider by using the corresponding `environment-values/kubeadm-capd` directory.)

If you are using a corporate proxy, you should also provide proxy URL in the values files `environment-values/my-rke2-capd/values.yaml`:

```yaml
proxies:
  http_proxy: http://your.company.proxy.url
  https_proxy: http://your.company.proxy.url
  no_proxy: 127.0.0.1,localhost,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
```

> You should pay attention and make sure that cluster_cidr (defaulting to 10.96.0.0/12) will be properly excluded by no_proxy, otherwise some units will attempt to use proxy for intra-cluster communications, and fail

Then you can launch the bootstrap process using provided configuration:

```shell
./bootstrap.sh environment-values/my-rke2-capd
```

In the above command, we're just using the default configuration, but you will probably want to modify these values to adapt to your needs and environment. In order to add units in your cluster, you can enable some [configuration components](environment-values/components) that are provided to add more units in your cluster (like Rancher, workload-clusters, a monitoring stack, aso...). For that purpose, add the reference to the targeted configuration component int your [environment-value's kustomization](environment-values/rke2-capd/kustomization.yaml)

For more details on environment-values generation you can have a look at the [dedicated README](environment-values/README.md).

> For environments where the CAPD host is behind a forward proxy (i.e. `proxies.http_proxy` in environment-values is not an empty string), the nodes of the single-node management and workload clusters will be automatically configured with the proper enviroment settings for the [containerd service](kustomize-units/cluster-manifests/components/proxies/KubeadmControlPlane/kustomization.yaml) (in CAPBK flavor) and [rke2-server and rke2-agent services](kustomize-units/cluster-manifests/components/proxies/RKE2ControlPlane/kustomization.yaml) (CAPBR falvor) respectively, by applying the proxies defined under `proxies`. <br/>
Also, the workload cluster's control plane node' /etc/resolv.conf for either [CAPBK](kustomize-units/cluster-manifests/components/dns-client/kind/KubeadmControlPlane/kustomization.yaml) or [CAPBR](kustomize-units/cluster-manifests/components/dns-client/kind/RKE2ControlPlane/kustomization.yaml) bootstrap flavors will be populated with the management cluster's k8s-gateway LoadBalancer service External IP (set by the `CLUSTER_EXTERNAL_IP` var of management cluster) to allow for resolving the Rancher FQDN. <br/>
Lastly, the management cluster's single-node Container Runtime will be configured with a container registry mirror endpoint for `docker.io` (to avoid Docker Hub rate limitting issues), the one defined by `dockerio_registry_mirror` in environment-values if this is not an empty string, for both the [CAPBK](kustomize-units/cluster-manifests/components/registry-mirror/KubeadmControlPlane/kustomization.yaml) and the [CAPBR](kustomize-units/cluster-manifests/components/registry-mirror/RKE2ControlPlane/kustomization.yaml) bootstrap flavors.

#### Accessing Rancher UI

First, one needs to open an SSH dynamic port forwarding tunnel to the CAPD host machine on a local port like 8887, while having the DNS mapping for `rancher.sylva` Ingress URL to the relevant IP address (one set by `.Values.cluster.cluster_external_ip` in all environments except rke2-capd, where the rke2-nginx-ingress-controller DaemonSet is working in host-networking and so this IP will be the management-cluster's single-node IP address) in `/etc/hosts` on the CAPD host.
Then, we set in Mozilla browser "General" > "Network Settings" > "Manual proxy configuration" a SOCKS v5 host for 127.0.0.1:8887 and enable "Proxy DNS when using SOCKS v5" to have DNS resolved by the CAPD host. <br/>
Finally, `rancher.sylva` can be reached in browser.

### Deploying clusters in OpenStack using CAPO

The workflow is quite similar to previous one with Docker, you'll only have to provide different variables:

Install kubectl and [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation), clone this project, and create a kind cluster:

```shell
kind create cluster --name bootstrap
```

Another prerequisite will be to reserve a pair of neutron ports that will be used as external IPs for management and sample workload cluster. These ports should be created in a network that is reachable from the bootstrap cluster (typically an external network).

 ```shell
openstack port create --network c314d52c-80fe-42b6-9092-55be383d1951 management-cluster-external
openstack port create --network c314d52c-80fe-42b6-9092-55be383d1951 workload-cluster-external
 ```

Create your own copy of environment-values (this will prevent you from accidentally committing your secrets). You can use rke2-capo directory if you intent to deploy rke2 clusters.

 ```shell
 cp -a environment-values/kubeadm-capo environment-values/my-capo-env
 ```

Provide your GitLab username and a GitLab token with read access to repository and registry:

```shell
cat <<EOF > environment-values/my-capo-env/git-secrets.env
username=your_name
password=glpat-xxxxxxxxxxxxxx
EOF
```

> **_NOTE:_** obviously, the files  `git-secrets.env` are sensitive and are meant to be ignored by Git  (see `.gitignore`). However, for the sake of security, it can be good idea to [secure these files with SOPS](./sops-howto.md) to mitigate the risk of leakage.

You will also have to provide yourOopenStack credentials in `environment-values/my-capo-env/secrets.yaml`

Then you'll have to adapt `environment-values/my-capo-env/secrets.yaml` to suit your environment:

```yaml
...
cluster:
  image: capo-ubuntu-2004-kube-v1.23.6-calico-3.23.1 # Image build with image-builder and uploaded in glance
  flavor:
    infra_provider: capo
    bootstrap_provider: cabpk
  capo:
    ssh_key_name: # put the name of your nova SSH keypair here, you'll need it if you intent to ssh to cluster nodes
    network_id: c314d52c-80fe-42b6-9092-55be383d1951 # The id of the network in which cluster nodes will be created (must be the same as the one in which you've reserved external IPs)
    cluster_external_ip: 1.2.3.4  # IP address of management-cluster-external port

proxies:
  http_proxy: http://your.company.proxy.url
  https_proxy: http://your.company.proxy.url
  no_proxy: 127.0.0.1,localhost,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8
```

Once this is done, you just need to run the bootstrap script:

```shell
./bootstrap.sh environment-values/my-capo-env
```

> For environments where an automatic creation of a workload cluster and its importing in Rancher server (deployed in the management cluster) workflow is triggered (like for _kubeadm-capo_) we have some traffic flow requirements:
>
> 1. since the [workload cluster's /etc/resolv.conf](./kustomize-units/cluster-manifests/kubeadm-capo/orange-falcon-single-node/kustomization.yaml#L99-115) would be configured with the management cluster's k8s-gateway LoadBalancer service External IP (set by the `KUBE_VIP_IP` var of management cluster) to allow for resolving the Rancher FQDN, we will need to also permit DNS traffic (UDP port 53) for the management cluster ingress direction.
> 2. since the workload cluster's [cattle-cluster-agent](https://docs.ranchermanager.rancher.io/v2.6/how-to-guides/new-user-guides/launch-kubernetes-with-rancher/about-rancher-agents#cattle-cluster-agent) will connect to the Rancher server FQDN (Ingress service External IP set by the `KUBE_VIP_IP` var of management cluster), we will need to also permit TLS traffic (TCP port 443) for the management cluster ingress direction, as per [Rancher downstream nodes port requirements](https://docs.ranchermanager.rancher.io/v2.6/getting-started/installation-and-upgrade/installation-requirements/port-requirements#downstream-kubernetes-cluster-nodes). Such traffic flow would also be needed for connecting to Rancher webUI.
If we are deploying both the management cluster and the workload cluster on the same Neutron network, like having all nodes attached to the same VLAN-based Provider Network, then these flows are permitted by default due to the fact that traffic internal to a Neutron network is not subject to Security Group-based filtering.
>
> However, if the management cluster and the workload cluster nodes would not share the same network (like using different Provider Networks), we can meet these requirements by setting the proper rules for the `default` SG of the OpenStack tenant in which the management cluster is deployed, since in the manifest of the _kubeadm-capo_ management cluster we're adding this [pre-existing SG to the spec of an OpenStackMachineTemplate](./kustomize-units/cluster-manifests/kubeadm-capo/base/management-cluster.yaml#L100-101).
To provide these rule in OpenStack, the tenant admin can run:
>
> ```console
>openstack security group rule create --ethertype IPv4 --ingress --protocol udp --dst-port 53 --remote-ip 0.0.0.0/0 --description "For k8s-gateway DNS resolving of Rancher" default
>openstack security group rule create --ethertype IPv4 --ingress --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0 --description "For Rancher importing" default
>```

### Installation without bootstrap, on a pre-existing cluster

The `apply.sh` script can be used to deploy the stack on a pre-existing cluster
without relying on the bootstrap stage at all. (It should also be used if you intent to perform changes on a bootstrapped management cluster after the pivot)

Assuming that the current `kubectl` context points to the target cluster and
that the environment values have been prepared under some `environment-values/xxxxx` directory, and that you've (at least) provided your Git credentials in `git-secrets.env` file, the following will deploy the stack:

```
./apply.sh <path/to/environment>
```

### Tips & Troubleshooting

As the stack if highly relying on flux, it is the main entry point to start with when something goes wrong. As all units are managed by kustomizations, this is the fist thing to look at:

```shell
kubectl get kustomizations
```

> You can also install and use use [flux cli](https://fluxcd.io/flux/installation/#install-the-flux-cli) to watch these ressources. As we are creating flux resources in default namespace, we recommand you to `export FLUX_SYSTEM_NAMESPACE=default`, this way you'll be able to issue flux commands without having to provide the namespace at each time. With flux cli, the equivalent of previous command would be `flux get kustomizations`

If you don't have any kustomization in your cluster, it means that the sylva-units chart has not been properly instantiated. In that case you should have a look at the resources that are managing that chart:

```shell
kubectl get gitrepositories.source.toolkit.fluxcd.io sylva-units
kubectl get helmcharts.source.toolkit.fluxcd.io default-sylva-units
kubectl get helmreleases.helm.toolkit.fluxcd.io sylva-units
```

If your management cluster is not properly deploying you should have a look at cluster-api resources:

```shell
kubectl get cluster
kubectl get machine
kubectl get openstackmachine
```

If you don't have enough info in the status of these resources, you can also have a look at the logs of capi infrastructure & bootstrap providers:

```shell
kubetail -n capo-system -s 12h
```

You can also install and use the [clusterctl tool](https://github.com/kubernetes-sigs/cluster-api/releases), it can be used to have a summary of the cluster deployment status:

```shell
clusterctl describe cluster management-cluster --show-conditions all
```

#### Working directly on the management cluster

Once the bootstrap phase is done, and the pivot is done, the management cluster can be updated with:

```
./apply.sh <your-environment-name>
```

### Cleaning things up
<!-- markdownlint-disable MD044 -->
One limitation of this approach is that management cluster can not delete himself properly, as it will shoot itself in the foot at some point. [openstack-cleanup.sh](tools/openstack-cleanup.sh) script is provided to help cleaning the resources created by capo.
<!-- markdownlint-enable MD044 -->