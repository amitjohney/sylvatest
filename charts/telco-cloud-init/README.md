# telco-cloud-init Helm charts

## Purpose

The key purpose of this chart is to facilitate the creation of the bootstrap cluster and the
follow-up with the creation with the management cluster, both sharing many commmon components.

The installation of the components is done thanks to FluxCD resources. And the dependency
resolution built-in Flux is used to orchestrate the creation of the management cluster after installing the base components on the bootstrap cluster, which is then followed by 
the deployments of components in the management cluster.

This chart also acts as the place where we handle "meta-release" aspect; ie. where we determine the different versions to use for the different components.

## Not a typical Helm chart

While most Helm charts create Deployments/ConfigMaps/Service/etc to deploy a given service,
this chart does not do this at all, it instantiates only Flux resources that tell Flux how
to deploy our components.

These resources are:
* Kustomization resources, pointing to git repositories in which kustomize `kustomization.yaml` and Kubernetes manifest files are defined describing how to deploy a component
* HelmRelease resources, which contain definitions of Helm releases for Helm charts hosted for instance on Git (or in Helm repos) with the wanted overridden Helm values.

## What this chart does

When instantiating this chart on the bootstrap cluster, this chart will:

* install CAPI and the desired providers, and their dependencies (e.g. cert-manager)
* install CAPI definitions for the management cluster
* install Flux on the management cluster
* instantiate itself on the management cluster (step 2 below)

When instantiating this chart on the management cluster, this chart will:

* install Flux resources for the management of Flux itself (to allow managing Flux itself via GitOps)
* install CAPI and the desired providers (and their dependencies)
* Flux definitions for any other component to deploy on the management cluster (Rancher, security tools, monitoring tools, etc.)

When a "pivot" setup is wanted, where the management cluster manages its own ClusterAPI
lifecycle with GitOps, the following additional actions are done:

* the installation of the chart on the bootstrap cluster triggers a pivot operation once
  CAPI components are installed on the management cluster
* the installation of the chart on the management cluster install Flux resources
  for the ClusterAPI definitions describing itself

## Usage

### Pre-requisite

Flux is already installed on the cluster on which the chart is being installed.

### Manual use of `helm`

* clone this repository

* ensure that FluxCD is installed on the local cluster

* prepare a file having the credentials needed to access git repos (and gitlab docker registry):

```terminal
$ cat < EOF > secrets.yaml
git_auth_default: 
  username: $GITLAB_USER
  password: $GITLAB_TOKEN

registry_secret:
  registry.gitlab.com:
    username: $GITLAB_USER
    password
```
* prepare the file(s) with the Helm overrides that you want:

```terminal
$ cat < EOF > myoverrides.yaml
phase: management  # e.g. to test the installation of the chart on the management cluster

cluster:
  flavor:
    infra_provider: capd
    bootstrap_provider: cabpr

components:
  capbr:
    enabled: true
  cappbr:
    enabled: true

  # this declares an override to deploy 'mydevbranch' branch
  # of https://gitlab.com/t6306/components/mycomponent.git/
  mycomponent:
    spec:
      ref:
        branch: mydevbranch

```
* install the Helm release (from this directory):

```
helm install telco-cloud-init chart --values secrets.yaml --values myoverrides.yaml
```

### Use of a FluxCD HelmRelease

We have a convenient way of deploying this chart with a form of inheritance of "layers" of
Helm overrides, to allow deploying and maintaining different flavors/specialization/parametrizations
of TelcoCloud, relying on kustomize overlays carrying the different layers that inject Helm
overrides into a FluxCD HelmRelease.

This is how this chart is used [in the context of this git repository](../../kustomize-components/telco-cloud-init/).

## Design notes

* no use case is identified to instantiate this chart multiple times in a
  given namespace, so this isn't supported (resource names aren't prefixed with the release name)

## TODO:

* use HelmRelease as top-level objects instead of Kustomization resources

* to allow the `telco-cloud-init` release on the management cluster to be handled via GitOps, we need
  to generate it via a Kustomization (or HelmRelease) defined in the management cluster itself (instead of via a
  Kustomization defined in the bootstrap cluster with a kubeConfig pointing to mgmt cluster) - this will require
  adding an intermediate Kustomization to do that

* have flux handle itself in the management cluster (currently broken when a proxy is needed)

* allow use of `{{ .Values.xxx }}` in  some or all values (requires passing values into gotpl interpreter)  (?)

* add gitlab CI for the chart:
  * helm linter
  * play `helm template` on a set of test `values.yaml` files
