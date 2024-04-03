# Deploying clusters in Docker using CAPD

Cluster API (CAPI) is a Kubernetes project that provides a declarative way to create, configure, and manage Kubernetes clusters. When running on Docker, Cluster API leverages Docker containers as the underlying infrastructure for creating and managing Kubernetes clusters.
Sylva supports 2 kubernetes flavors, kubeadm and rke2, both deployable with CAPD.

## Nodes as Docker containers

Each CAPD Kubernetes node is typically represented by a Docker container.
The default image for a node (kindest/node:v1.27.10) utilized by the can be replaced with a custom image (Ex: `registry.gitlab.com/sylva-projects/sylva-elements/container-images/rke2-in-docker:v1-27-10-rke2r1`) by setting the `cluster.capd.image_name` field in the environment-values.

<details><summary>
Docker output (click to expand)
</summary>

```bash
server:~/sylva-core$ docker ps
CONTAINER ID   IMAGE                                COMMAND                  CREATED        STATUS        PORTS                              NAMES
c3fd52c00fd4   kindest/node:v1.27.10                "/usr/local/bin/entr…"   16 hours ago   Up 16 hours   0/tcp, 127.0.0.1:32799->6443/tcp   management-cluster-control-plane-zqpvr
c44e9b26175d   kindest/haproxy:v20230510-486859a6   "haproxy -W -db -f /…"   16 hours ago   Up 16 hours   0/tcp, 0.0.0.0:32788->6443/tcp     management-cluster-lb
6b5c4c429e25   kindest/node:v1.29.2                 "/usr/local/bin/entr…"   16 hours ago   Up 16 hours ago   127.0.0.1:39875->6443/tcp         sylva-control-plane
```

</details>

## Cluster API Objects

Cluster API defines custom Kubernetes resources (CRDs) to represent various components of a Kubernetes cluster. These include:

- Cluster: Represents a Kubernetes cluster and defines its configuration.
- DockerCluster: Represents a provider-specific configuration used by Cluster API (CAPI) to manage Kubernetes clusters deployed on Docker containers. It defines Docker-specific settings and configurations required for creating and managing the Kubernetes cluster on Docker.
- KubeadmControlPlane:  Represents the control plane configuration for a Kubernetes cluster managed by kubeadm. ( Kubeadm usecase)
- RKE2ControlPlane: Represents the control plane configuration for the RKE2 distribution of Kubernetes. It defines the desired state and configuration of control plane components such as etcd, kube-apiserver, kube-controller-manager, and kube-scheduler. (RKE usecase, for kubeadm the corresponding object is KubeadmControlPlane)
- DockerMachineTemplate: Represents a template used to define the configuration of a machine (a Kubernetes node) within the cluster.
- DockerMachine: Represents a Docker container that acts as a Kubernetes node within the cluster. It defines the desired state and configuration of the Docker container, including image, labels, environment variables, and volume mounts.
- Machine: Represents a node in the Kubernetes cluster, such as control plane nodes or worker nodes.

<details><summary>
Cluster API Objects output (click to expand)
</summary>

- Cluster

```bash
server-1:~/sylva-core$ kubectl --kubeconfig management-cluster-kubeconfig get Cluster management-cluster -o yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  annotations:
    helm.sh/resource-policy: keep
    meta.helm.sh/release-name: cluster
    meta.helm.sh/release-namespace: sylva-system
  finalizers:
  - cluster.cluster.x-k8s.io
  generation: 2
  labels:
    app.kubernetes.io/managed-by: Helm
    cluster.x-k8s.io/cluster-name: management-cluster
    helm.toolkit.fluxcd.io/name: cluster
    helm.toolkit.fluxcd.io/namespace: sylva-system
  name: management-cluster
  namespace: sylva-system
spec:
  clusterNetwork:
    pods:
      cidrBlocks:
      - 100.72.0.0/16
    serviceDomain: cluster.local
    services:
      cidrBlocks:
      - 100.73.0.0/16
  controlPlaneEndpoint:
    host: 10.11.1.3
    port: 6443
  controlPlaneRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1alpha1
    kind: RKE2ControlPlane
    name: management-cluster-control-plane
    namespace: sylva-system
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: DockerCluster
    name: management-cluster
    namespace: sylva-system
```

- DockerCluster

```bash
server:~/sylva-core$ kubectl --kubeconfig management-cluster-kubeconfig get DockerCluster -o yaml 
apiVersion: v1
kind: List
metadata:
  resourceVersion: ""
items:
- apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
  kind: DockerCluster
  metadata:
    annotations:
      meta.helm.sh/release-name: cluster
      meta.helm.sh/release-namespace: sylva-system
    finalizers:
    - dockercluster.infrastructure.cluster.x-k8s.io
    generation: 1
    labels:
      app.kubernetes.io/managed-by: Helm
      cluster.x-k8s.io/cluster-name: management-cluster
      helm.toolkit.fluxcd.io/name: cluster
      helm.toolkit.fluxcd.io/namespace: sylva-system
    name: management-cluster
    namespace: sylva-system
    ownerReferences:
    - apiVersion: cluster.x-k8s.io/v1beta1
      blockOwnerDeletion: true
      controller: true
      kind: Cluster
      name: management-cluster
  spec:
    controlPlaneEndpoint:
      host: 10.11.1.3
      port: 6443
    loadBalancer:
      customHAProxyConfigTemplateRef:
        name: lb-config
```

- KubeadmControlPlane

```bash
server:~/sylva-core$ kubectl --kubeconfig management-cluster-kubeconfig get KubeadmControlPlane management-cluster-control-plane -o yaml
apiVersion: controlplane.cluster.x-k8s.io/v1beta1
kind: KubeadmControlPlane
metadata:
  annotations:
    helm.sh/resource-policy: keep
    meta.helm.sh/release-name: cluster
    meta.helm.sh/release-namespace: sylva-system
  finalizers:
  - kubeadm.controlplane.cluster.x-k8s.io
  generation: 1
  labels:
    app.kubernetes.io/managed-by: Helm
    cluster.x-k8s.io/cluster-name: management-cluster
    helm.toolkit.fluxcd.io/name: cluster
    helm.toolkit.fluxcd.io/namespace: sylva-system
  name: management-cluster-control-plane
  namespace: sylva-system
  ownerReferences:
  - apiVersion: cluster.x-k8s.io/v1beta1
    blockOwnerDeletion: true
    controller: true
    kind: Cluster
    name: management-cluster
spec:
  kubeadmConfigSpec:
    clusterConfiguration:
      apiServer:
        certSANs:
        - localhost
        - 127.0.0.1
      controllerManager:
        extraArgs:
          enable-hostpath-provisioner: "true"
      dns: {}
      etcd:
        local:
          extraArgs:
            auto-compaction-mode: periodic
            auto-compaction-retention: 12h
            quota-backend-bytes: "4294967296"
      networking: {}
      scheduler: {}
    format: cloud-config
    initConfiguration:
      localAPIEndpoint: {}
      nodeRegistration:
        imagePullPolicy: IfNotPresent
        kubeletExtraArgs:
          anonymous-auth: "false"
          eviction-hard: nodefs.available<0%,nodefs.inodesFree<0%,imagefs.available<0%
          max-pods: "196"
          register-with-taints: ""
        taints: []
    joinConfiguration:
      discovery: {}
      nodeRegistration:
        imagePullPolicy: IfNotPresent
        kubeletExtraArgs:
          anonymous-auth: "false"
          eviction-hard: nodefs.available<0%,nodefs.inodesFree<0%,imagefs.available<0%
          max-pods: "196"
          register-with-taints: ""
        taints: []
    postKubeadmCommands:
    - set -e
    preKubeadmCommands:
    - set -e
    - echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
    - echo "fs.inotify.max_user_instances = 512" >> /etc/sysctl.conf
    - sysctl --system
    - |2

      c=/etc/containerd/config.toml

      # Remove default mirroring configuration for k8s.gcr.io as it can't coexist with registry config dir
      sed -i '/k8s.gcr.io/d' $c
      if ! grep -q "config_path *=.*/etc/containerd/registry.d" $c; then
        cp $c $c.orig
        if ! grep -q  '"io.containerd.grpc.v1.cri".registry\]' $c ; then
          # we add the missing section
          echo '[plugins."io.containerd.grpc.v1.cri".registry]' >> $c
          echo '  config_path = "/etc/containerd/registry.d"' >> $c
        else
          # we assume that it's a recent containerd config file, already having config_path set for this section
          sed -i -e '/io.containerd.grpc.v1.cri".registry\]/ { n; s|config_path.*|config_path = "/etc/containerd/registry.d"| }' $c
        fi
      fi
    - systemctl restart containerd.service
    - systemctl daemon-reload && systemctl restart containerd.service
    - set -e
    - ""
    - echo 'alias kubectl="KUBECONFIG=/etc/kubernetes/admin.conf kubectl"' >> /root/.bashrc
    - echo "Preparing Kubeadm bootstrap" > /var/log/my-custom-file.log
  machineTemplate:
    infrastructureRef:
      apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
      kind: DockerMachineTemplate
      name: management-cluster-cp-7f8eda245b
      namespace: sylva-system
    metadata: {}
  replicas: 1
  rolloutStrategy:
    rollingUpdate:
      maxSurge: 1
    type: RollingUpdate
  version: v1.27.3
```

- RKE2ControlPlane for RKE usecase

```bash
server:~/sylva-core$ kubectl --kubeconfig management-cluster-kubeconfig get RKE2ControlPlane -o yaml
apiVersion: v1
kind: List
items:
- apiVersion: controlplane.cluster.x-k8s.io/v1alpha1
  kind: RKE2ControlPlane
  metadata:
    annotations:
      helm.sh/resource-policy: keep
      meta.helm.sh/release-name: cluster
      meta.helm.sh/release-namespace: sylva-system
    finalizers:
    - rke2.controleplane.cluster.x-k8s.io
    generation: 1
    labels:
      app.kubernetes.io/managed-by: Helm
      cluster.x-k8s.io/cluster-name: management-cluster
      helm.toolkit.fluxcd.io/name: cluster
      helm.toolkit.fluxcd.io/namespace: sylva-system
    name: management-cluster-control-plane
    namespace: sylva-system
    ownerReferences:
    - apiVersion: cluster.x-k8s.io/v1beta1
      blockOwnerDeletion: true
      controller: true
      kind: Cluster
      name: management-cluster
  spec:
    agentConfig:
      additionalUserData:
        config: |
          {}
      format: cloud-config
      kubelet:
        extraArgs:
        - anonymous-auth=false
        - config=kubelet-configuration-file.yaml
        - eviction-hard=nodefs.available<0%,nodefs.inodesFree<0%,imagefs.available<0%
        - max-pods=196
      nodeLabels:
      - sylva.org/label-scope=test
      version: v1.27.10+rke2r1
    files:
    - content: "---\napiVersion: kubelet.config.k8s.io/v1beta1\nkind: KubeletConfiguration\n
        \n"
      owner: root:root
      path: /var/lib/rancher/rke2/server/kubelet-configuration-file.yaml
      permissions: "0644"
    infrastructureRef:
      apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
      kind: DockerMachineTemplate
      name: management-cluster-cp-95ba9a4bda
    manifestsConfigMapReference: {}
    nodeDrainTimeout: 5m0s
    postRKE2Commands:
    - set -e
    preRKE2Commands:
    - set -e
    - |
      echo "No update" > /var/lib/grub-init
    - echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
    - echo "fs.inotify.max_user_instances = 512" >> /etc/sysctl.conf
    - sysctl --system
    - echo 'alias ctr="/var/lib/rancher/rke2/bin/ctr --namespace k8s.io --address
      /run/k3s/containerd/containerd.sock"' >> /root/.bashrc
    - echo 'alias crictl="/var/lib/rancher/rke2/bin/crictl --runtime-endpoint /run/k3s/containerd/containerd.sock"'
      >> /root/.bashrc
    - echo 'alias kubectl="KUBECONFIG=/etc/rancher/rke2/rke2.yaml /var/lib/rancher/rke2/bin/kubectl"'
      >> /root/.bashrc
    - echo "Preparing RKE2 bootstrap" > /var/log/my-custom-file.log
    privateRegistriesConfig: {}
    registrationAddress: 10.11.1.100
    registrationMethod: internal-first
    replicas: 1
    rolloutStrategy:
      rollingUpdate:
        maxSurge: 1
      type: RollingUpdate
    serverConfig:
      cni: calico
      disableComponents:
        pluginComponents:
        - rke2-ingress-nginx
      etcd:
        backupConfig: {}
        customConfig:
          extraArgs:
          - auto-compaction-mode=periodic
          - auto-compaction-retention=12h
          - quota-backend-bytes=4294967296
      tlsSan:
      - localhost
      - 127.0.0.1
```

- DockerMachineTemplate

```bash
server:~/sylva-core$ kubectl --kubeconfig management-cluster-kubeconfig get DockerMachineTemplate management-cluster-cp-95ba9a4bda -o yaml
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: DockerMachineTemplate
metadata:
  annotations:
    helm.sh/resource-policy: keep
    meta.helm.sh/release-name: cluster
    meta.helm.sh/release-namespace: sylva-system
  labels:
    app.kubernetes.io/managed-by: Helm
    helm.toolkit.fluxcd.io/name: cluster
    helm.toolkit.fluxcd.io/namespace: sylva-system
  name: management-cluster-cp-95ba9a4bda
  namespace: sylva-system
spec:
  template:
    spec:
      customImage: registry.gitlab.com/sylva-projects/sylva-elements/container-images/rke2-in-docker:v1-24-12-rke2r1
      extraMounts:
      - containerPath: /var/run/docker.sock
        hostPath: /var/run/docker.sock
```

- DockerMachine

```bash
server:~/sylva-core$ kubectl --kubeconfig management-cluster-kubeconfig get DockerMachine management-cluster-cp-95ba9a4bda-692z5 -o yaml
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: DockerMachine
metadata:
  annotations:
    cluster.x-k8s.io/cloned-from-groupkind: DockerMachineTemplate.infrastructure.cluster.x-k8s.io
    cluster.x-k8s.io/cloned-from-name: management-cluster-cp-95ba9a4bda
  finalizers:
  - dockermachine.infrastructure.cluster.x-k8s.io
  generation: 1
  labels:
    cluster.x-k8s.io/cluster-name: management-cluster
  name: management-cluster-cp-95ba9a4bda-692z5
  namespace: sylva-system
  ownerReferences:
  - apiVersion: cluster.x-k8s.io/v1beta1
    blockOwnerDeletion: true
    controller: true
    kind: Machine
    name: management-cluster-control-plane-hwbw7
spec:
  bootstrapped: true
  customImage: registry.gitlab.com/sylva-projects/sylva-elements/container-images/rke2-in-docker:v1-24-12-rke2r1
  extraMounts:
  - containerPath: /var/run/docker.sock
    hostPath: /var/run/docker.sock
  providerID: docker:////management-cluster-control-plane-hwbw7
status:
  addresses:
  - address: management-cluster-control-plane-hwbw7
    type: Hostname
  - address: 10.11.1.4
    type: InternalIP
  - address: 10.11.1.4
    type: ExternalIP
  conditions:
  - lastTransitionTime: "2024-03-26T10:16:19Z"
    status: "True"
    type: Ready
  - lastTransitionTime: "2024-03-26T10:16:19Z"
    status: "True"
    type: ContainerProvisioned
  ready: true
```

- Machine

```bash
server:~/sylva-core$ kubectl --kubeconfig management-cluster-kubeconfig get Machine management-cluster-control-plane-hwbw7 -o yaml
apiVersion: cluster.x-k8s.io/v1beta1
kind: Machine
metadata:
  annotations:
    controlplane.cluster.x-k8s.io/rke2-server-configuration: '{"tlsSan":["localhost","127.0.0.1"],"disableComponents":{"pluginComponents":["rke2-ingress-nginx"]},"cni":"calico","etcd":{"backupConfig":{},"customConfig":{"extraArgs":["auto-compaction-mode=periodic","auto-compaction-retention=12h","quota-backend-bytes=4294967296"]}}}'
  finalizers:
  - machine.cluster.x-k8s.io
  generation: 1
  labels:
    cluster.x-k8s.io/cluster-name: management-cluster
    cluster.x-k8s.io/control-plane: ""
  name: management-cluster-control-plane-hwbw7
  namespace: sylva-system
  ownerReferences:
  - apiVersion: controlplane.cluster.x-k8s.io/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: RKE2ControlPlane
    name: management-cluster-control-plane
spec:
  bootstrap:
    configRef:
      apiVersion: bootstrap.cluster.x-k8s.io/v1alpha1
      kind: RKE2Config
      name: management-cluster-control-plane-zn4tq
      namespace: sylva-system
      uid: 26694113-1de3-470b-b3ad-0c8965215396
    dataSecretName: management-cluster-control-plane-zn4tq
  clusterName: management-cluster
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
    kind: DockerMachine
    name: management-cluster-cp-95ba9a4bda-692z5
    namespace: sylva-system
    uid: 3b32d4ee-9f84-43ff-af09-11c2f363d568
  nodeDeletionTimeout: 10s
  nodeDrainTimeout: 5m0s
  providerID: docker:////management-cluster-control-plane-hwbw7
  version: v1.27.10+rke2r1
```

</details>

## The flow between Components

The flow between Docker components and Kubernetes objects involves the provisioning of Docker containers as Kubernetes nodes, the setup of control plane components, and the management of worker nodes within the cluster.

### Kubeadm

- Cluster Creation: To create a Kubernetes cluster, a Cluster API controller watches for Cluster resource creation events. When a Cluster resource is created, the controller initiates the cluster creation process.
- Node Provisioning: When a Machine resource is created, the Cluster API controller provisions a Docker container (representing a Kubernetes node) based on the specified configuration. This may involve creating a Docker container using a base image with Kubernetes components installed.
- Control Plane Setup: For control plane nodes, additional configuration may be applied using KubeadmControlPlane resources. This includes setting up etcd, kube-apiserver, kube-controller-manager, kube-scheduler, and other components required for the control plane.
Worker Node Join: Worker nodes join the cluster by communicating with the control plane nodes. This typically involves running kubeadm join commands within Docker containers to join the cluster.
- Cluster Management: Once the cluster is up and running, the Cluster API controller monitors the state of the cluster and nodes. It reconciles any discrepancies between the desired state (defined by the Cluster API resources) and the actual state of the cluster.
- Scaling: Scaling the cluster involves creating or deleting Machine resources. When new Machine resources are created, new Docker containers are provisioned as worker nodes and joined to the cluster. Conversely, deleting Machine resources results in the corresponding Docker containers being removed from the cluster.

### RKE

When using RKE (Rancher Kubernetes Engine) with Cluster API (CAPI) to manage Kubernetes clusters on Docker containers follows a similar flow as using kubeadm, but with RKE-specific provisioning and management steps tailored to Docker containerization. RKE handles the orchestration of Docker containers and the setup of Kubernetes components within those containers, enabling the creation and management of Kubernetes clusters in a declarative manner through Cluster API resources.

- Cluster Creation: To create a Kubernetes cluster with RKE, a Cluster API controller watches for Cluster resource creation events. When a Cluster resource is created, the controller initiates the cluster creation process.
- Node Provisioning: When a Machine resource is created, the Cluster API controller instructs RKE to provision Docker containers representing Kubernetes nodes based on the specified configuration. RKE interacts with Docker to create and manage these containers.
- Control Plane Setup: For control plane nodes, RKE provisions Docker containers with the necessary Kubernetes components, including etcd, kube-apiserver, kube-controller-manager, kube-scheduler, and others. RKE also handles the setup and configuration of these components within the Docker containers.
- Worker Node Join: Worker nodes join the cluster by communicating with the control plane nodes. RKE orchestrates the worker node join process, which may involve running specific commands within Docker containers to join the cluster.
- Cluster Management: Once the cluster is up and running, the Cluster API controller monitors the state of the cluster and nodes. It reconciles any discrepancies between the desired state (defined by the Cluster API resources) and the actual state of the cluster, similar to the kubeadm-based flow.
- Scaling: Scaling the cluster involves creating or deleting Machine resources. When new Machine resources are created, the Cluster API controller instructs RKE to provision additional Docker containers as worker nodes and join them to the cluster. Deleting Machine resources results in the corresponding Docker containers being removed from the cluster.

## HAProxy LB config

HA proxy default config can be [customized](https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster/-/blob/main/templates/capd-rke-lb-configmap.yaml?ref_type=heads) with the help of a config map. This config is used to update the /usr/local/etc/haproxy/haproxy.cfg file on management-cluster-lb Docker container.

<details><summary>
HAproxy ConfigMap output (click to expand)
</summary>

```bash
server:~/sylva-core$ kubectl get cm lb-config -o yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    kustomize.toolkit.fluxcd.io/name: capd
    kustomize.toolkit.fluxcd.io/namespace: sylva-system
  name: lb-config
  namespace: sylva-system
data:
  value: "# generated by kind\nglobal\n  log /dev/log local0\n  log /dev/log local1
    notice\n  daemon\n  # limit memory usage to approximately 18 MB\n  # (see https://github.com/kubernetes-sigs/kind/pull/3115)\n
    \ maxconn 100000\n\nresolvers docker\n  nameserver dns 127.0.0.11:53\n\ndefaults\n
    \ log global\n  mode tcp\n  option dontlognull\n  # TODO: tune these\n  timeout
    connect 5000\n  timeout client 50000\n  timeout server 50000\n  # allow to boot
    despite dns don't resolve backends\n  default-server init-addr none\n\nfrontend
    stats\n  bind *:8404\n  stats enable\n  stats uri /\n  stats refresh 10s\n\nfrontend
    control-plane\n  bind *:{{ .FrontendControlPlanePort }}\n  {{ if .IPv6 -}}\n  bind
    :::{{ .FrontendControlPlanePort }};\n  {{- end }}\n  default_backend kube-apiservers\n\nbackend
    kube-apiservers\n  option httpchk GET /healthz\n  http-check expect status 401\n
    \ # TODO: we should be verifying (!)\n  {{range $server, $address := .BackendServers}}\n
    \ server {{ $server }} {{ JoinHostPort $address $.BackendControlPlanePort }} check
    check-ssl verify none resolvers docker resolve-prefer {{ if $.IPv6 -}} ipv6 {{-
    else -}} ipv4 {{- end }}\n  {{- end}}\n\nfrontend rke2-join\n  bind *:9345\n  {{
    if .IPv6 -}}\n  bind :::9345;\n  {{- end }}\n  default_backend rke2-servers\n\nbackend
    rke2-servers\n  option httpchk GET /v1-rke2/readyz\n  http-check expect status
    403\n  {{range $server, $address := .BackendServers}}\n  server {{ $server }}
    {{ $address }}:9345 check check-ssl verify none\n  {{- end}}\n  "
```

</details>
