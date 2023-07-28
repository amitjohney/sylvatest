# Kata Containers in Sylva


The kustomize unit `kata-deploy` introduces additional container isolation for untrusted pods. The default state of the unit is disabled. It is recommended to enable `kata-deploy`  on workload clusters hosting untrused applications. TThe unit introduces a `kyverno` policy to enforce `kata containers` runtime based on `untrusted` label.. 

The unit is validated on both the bootstrap providers ( `kubeadm` and `rke2` ) and on `capo` infra provider. Kata container on infra provider `capm3` is still pending.

This feature needs to have hardware virtualization enabled on the underlying nodes. In the testing part, this setting seems to be enabled by default on the CAPO. For now, there is no validation implemented to check if it is enabled or not. In future, if required validation can be added.

## Related reference(s)

[rfe 16](https://gitlab.com/sylva-projects/sylva/-/merge_requests/16)

[kata-containers](https://github.com/kata-containers/kata-containers/)

## Manual steps to check for kata containers

- Check for kata-deploy daemonsets in kube-system namespace
- Check for runtimeclass kata-qemu.
- Check for kyverno policy by the name `kata-containers-on-untrusted-pod`
- Add a label `untrusted: "true"` to untrusted pod, the runtimeclassname should be added as kata-qemu.

### Output Expected

Already created two similar pods with a difference in label as mentioned in manual steps. Pods manifests looks like :

### Trusted Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu
spec:
  containers:
  - name: ubuntu
    image: ubuntu:20.04
    command: ['sh', '-c', 'sleep 3600']
kubectl --kubeconfig management-cluster-kubeconfig describe po ubuntu
Name:             ubuntu
Namespace:        default
Priority:         0
Service Account:  default

`````

### Pod with kata containers

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-kata
  labels:
    untrusted: "true"
spec:
  containers:
  - name: ubuntu
    image: ubuntu:20.04
    command: ['sh', '-c', 'sleep 3600']

kubectl --kubeconfig management-cluster-kubeconfig describe po ubuntu-kata

Name:                ubuntu-kata
Namespace:           default
Priority:            0
Runtime Class Name:  kata-qemu
Service Account:     default

`````

### Kernel version output inside Pods-

```
kubectl --kubeconfig management-cluster-kubeconfig exec -it ubuntu -- /bin/bash
root@ubuntu:/# uname -a
Linux ubuntu 5.4.0-105-generic #119-Ubuntu SMP Mon Mar 7 18:49:24 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux `

kubectl --kubeconfig management-cluster-kubeconfig exec -it ubuntu-kata -- /bin/bash
root@ubuntu-kata:/# uname -a
Linux ubuntu-kata 5.19.2 #1 SMP Wed Apr 26 04:41:36 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux 
```
