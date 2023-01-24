# How to use capi-bootstrap

## Access UIs when in CAPD behind Proxy

```shell

# if the CAPD host is a Linux machine with address 172.20.129.247 behind the http://192.168.200.188:3128 proxy, one could use:
boburciu@WX-5CG020BDT2:~$  ssh -i ~/.ssh/boburciu_key_pair_rocket.pem -l ubuntu 172.20.129.247 -o ProxyCommand='socat - PROXY:192.168.200.188:%h:%p,proxyport=3128' -D 8887
ubuntu@capi-bootstrap-capd-bb:~$ docker ps | grep management-cluster
d6272b7f2b52   registry.gitlab.com/t6306/components/docker-images/rke2-in-docker:v1-24-4-rke2r1   "/usr/local/bin/entr…"   2 weeks ago    Up 2 weeks    9345/tcp, 44847/tcp, 127.0.0.1:44847->6443/tcp   management-cluster-control-plane-pphgf
4f06a372706d   kindest/haproxy:v20210715-a6da3463                                                 "haproxy -sf 7 -W -d…"   2 weeks ago    Up 2 weeks    45453/tcp, 0.0.0.0:45453->6443/tcp               management-cluster-lb
ubuntu@capi-bootstrap-capd-bb:~$
ubuntu@capi-bootstrap-capd-bb:~$ docker exec -it management-cluster-control-plane-pphgf sh -c "/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml  get ing -A"
NAMESPACE       NAME                      CLASS    HOSTS           ADDRESS        PORTS     AGE
cattle-system   rancher                   <none>   rancher.sylva   172.27.0.5     80, 443   9m
flux-system     flux-webui-weave-gitops   nginx    flux.sylva      172.19.0.100   80        14m
vault           vault                     <none>   vault.sylva     172.19.0.100   80, 443   13m
ubuntu@capi-bootstrap-capd-bb:~$ cat /etc/hosts | grep rancher.sylva
172.27.0.5 rancher.sylva flux.sylva vault.sylva   # DNS mapping for Ingress URLs to the relevant IP address
ubuntu@capi-bootstrap-capd-bb:~$ docker ps | grep management-cluster

# and the just use the browser with a SOCKS v5 host for 127.0.0.1:8887 and enable "Proxy DNS when using SOCKS v5". The UIs will then be available.
```

## Move past Docker Hub rate limitting

You can [run a local registry mirror](https://docs.docker.com/registry/recipes/mirror/#run-a-registry-as-a-pull-through-cache) and have the management cluster be configured with a `docker.io` registry mirror to point to it by setting `dockerio_registry_mirror` in environment-values with its endpoint. <br/>
As an example, for CAPO Orange environments this is `dockerio_registry_mirror: "http://172.20.129.142"`, while for Orange managed GitLab runners this is `dockerio_registry_mirror: "http://192.168.74.5"`, set inside the runner [runners.environment](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section) in variable `DOCKERIO_REGISTRY_MIRROR`.
