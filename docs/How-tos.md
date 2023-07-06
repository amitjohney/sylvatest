# How to use sylva-core

## Access UIs when in CAPD behind Proxy

```shell

# if the CAPD host is a Linux machine with address 172.20.129.247 behind the http://192.168.200.188:3128 proxy, one could use:
boburciu@WX-5CG020BDT2:~$  ssh -i ~/.ssh/boburciu_key_pair_rocket.pem -l ubuntu 172.20.129.247 -o ProxyCommand='socat - PROXY:192.168.200.188:%h:%p,proxyport=3128' -D 8887
ubuntu@sylva-core-capd-bb:~$ docker ps | grep management-cluster
d6272b7f2b52   registry.gitlab.com/sylva-projects/sylva-elements/container-images/rke2-in-docker:v1-24-4-rke2r1   "/usr/local/bin/entr…"   2 weeks ago    Up 2 weeks    9345/tcp, 44847/tcp, 127.0.0.1:44847->6443/tcp   management-cluster-control-plane-pphgf
zsh:1: command not found: q
ubuntu@sylva-core-capd-bb:~$
ubuntu@sylva-core-capd-bb:~$ docker exec -it management-cluster-control-plane-pphgf sh -c "/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml  get ing -A"
NAMESPACE       NAME                      CLASS    HOSTS           ADDRESS        PORTS     AGE
cattle-system   rancher                   <none>   rancher.sylva   172.27.0.5     80, 443   9m
flux-system     flux-webui-weave-gitops   nginx    flux.sylva      172.19.0.100   80        14m
vault           vault                     <none>   vault.sylva     172.19.0.100   80, 443   13m
ubuntu@sylva-core-capd-bb:~$ cat /etc/hosts | grep rancher.sylva
172.27.0.5 rancher.sylva flux.sylva vault.sylva   # DNS mapping for Ingress URLs to the relevant IP address
ubuntu@sylva-core-capd-bb:~$ docker ps | grep management-cluster

# and the just use the browser with a SOCKS v5 host for 127.0.0.1:8887 and enable "Proxy DNS when using SOCKS v5". The UIs will then be available.
```

## Move past Docker Hub rate limiting

You can [run a local registry mirror](https://docs.docker.com/registry/recipes/mirror/#run-a-registry-as-a-pull-through-cache) and have the management cluster be configured with a `docker.io` registry mirror to point to it by configuring `registry_mirrors` in environment-values with its endpoint.

```yaml
registry_mirrors:
  hosts_config:
    docker.io:
    - mirror_url: http://your.mirror/docker
```

## Expose management cluster API through floatingIP for bootstrap in CAPO

When deploying management cluster in OpenStack, you can specify to which network you want the cluster nodes VMs (their OpenStack ports) to be attached by using `cluster.capo.network_id`.

In some cases, this virtual network (VN) will not be accessible to the bootstrap cluster (like when deploying the VMs on an isolated network behind an OpenStack router with Source NAT enabled and using a remote bootstrap machine without direct connectivity inside `cluster.capo.network_id` defined VN), so bootstrap cluster is not able to reach the Kubernetes API to confirm that node is ready.

You can specify `cluster.capo.external_network_id` to create a floating IP and expose your cluster to outside. However by default the floating IP is not used for accessing cluster API and bootstrap cluster will still try to access management cluster API via internal access.

In order to have this CAPI controller make use of the “FIP public” address, the following values can be used:

```yaml
units:
  cluster:
    helmrelease_spec:
      _postRenderers:
        - kustomize:
            patches:
              - target:
                  kind: OpenStackCluster
                patch: |
                  - op: replace
                    path: /spec/apiServerFixedIP
                    value: {{ .Values.cluster.capo.floating_ip }}
```

With such values, `management-cluster-kubeconfig` will be pointing to floating IP and bootstrap cluster would no longer need to have access to internal network directly.

**Advanced explanation:**  
During bootstap, the CAPI controller inside bootstrap cluster will need to reach the Kubernetes API of the first management cluster node to confirm that node is ready (as covered by the [Cluster reconciliation process]( https://cluster-api.sigs.k8s.io/developer/architecture/controllers/cluster.html)).  
Due to the fact that both kube-api exposure solutions used today (kube-vip for Kubeadm and MetalLB for RKE2 clusters) work in L2 mode, using a `.Values.cluster.cluster_external_ip` from a different VN than the one set for nodes will limit the ARP entry for it to the nodes (`cluster.capo.network_id`) VN, making it unreachable for outside sources trying to reach that `.Values.cluster.cluster_external_ip` address.  
The `sylva-core` CAPO solution does offer the option to specify in environment values the `cluster.capo.external_network_id` with a different VN than `cluster.capo.network_id` in order to create an OpenStack Floating IP and attach that to a port in `cluster.capo.network_id`, one with the address of `.Values.cluster.cluster_external_ip`, which efectively translates to having your cluster’s kube-api (and other Ingress services) exposed to outside.  
However, by default the bootstrap cluster CAPI controller will use the address defined in `OpenStackCluster.spec.apiServerFixedIP` for accessing the cluster’s Kubernetes API and with that set to `.Values.cluster.cluster_external_ip`, this means it will still use the “FIP internal” (from `cluster.capo.network_id` subnet) address.
