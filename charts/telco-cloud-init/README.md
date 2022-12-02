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
```
* prepare the file(s) with the Helm overrides that you want:

```terminal
$ cat < EOF > myoverrides.yaml
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

## Component definitions examples

To define a new component, an entry can be added under `components` in values (either in `values.yaml` in the chart,
or in the values of the chart overriden for a given deployment flavor or for a given deployment).

### Component using a kustomization defined in capi-boostrap repo

```yaml
components:

  my-component:
    repo: capi-bootstrap   # this refers to .git_repo_templates.capi-bootstrap (defined in default values)
    kustomization_spec:
      path: ./kustomize-component/myComponent
    depends_on:
      - name: my-other-component  # my-component will not be deployed before my-other-component is ready
```

### Component using a kustomization defined in another repository

```yaml
git_repo_templates:
  project-foo:
    spec:
      url: https://gitlab.com/t6306/components/foo.git

components:

  my-component:
    repo: project-foo
    kustomization_spec:
      path: ./kustomize  # this will point to https://gitlab.com/t6306/components/foo.git / kustomize
```

### Component using a Helm chart defined in a git repository

```yaml
git_repo_templates:
  helm-chart-bar:
    spec:
      url: https://gitlab.com/t6306/helm-charts/bar.git
      ref:
        tag: v1.0.3

components:

  my-component:
    repo: helm-chart-bar
    helmrelease_spec:
      chart:
        spec:
          chart: ./my-chart   # this will point to https://gitlab.com/t6306/helm-charts/bar.git / my-chart  on tag v1.0.3
```

With this type of component definition, Flux will reconciliate the HelmRelease based
on the git revision (ignoring version field in the Helm chart `Chart.yaml` file).

### Component using a Helm chart defined in a Helm repository

```yaml
components:

  cert-manager:
    helm_repo_url: https://charts.jetstack.io
    helmrelease_spec:
      chart:
        spec:   # this will use v1.8.2 of the cert-manager chart found in the Helm repo at https://charts.jetstack.io
          chart: cert-manager
          version: v1.8.2
```

### How to feed settings coming from Helm values into the configuration of components

You can use Helm templating to feed settings coming from values into
the configuration of your components:

```yaml
mgmt_cluster_domain_name: my-mgmt-cluster.foo.org

components:

  foo:
    ...
    helmrelease_spec:
      ...
      values:
        externalName: "{{ .Values.mgmt_cluster_domain_name }}"

    helm_secret_values: ## this is well suited to secure credentials (what is set here will be stored in a Secret, mapped into the valuesFrom field of the HelmRelease)
      password: '{{ .Values.foo_password }}'

  bar:
    ...
    kustomization_spec:
      ...
      postBuild:
        substitute:
          MAIN_URL: "https://bar-{{ .Values.mgmt_cluster_domain_name }}"

    kustomization_substitute_secrets:  ## this is well suited to secure credentials (what is set here will be stored in a Secret, mapped into the postBuild.substituteFrom field of the Kustomization)
      FOO_PASSWORD: bar

```

(watch out for limitations, as explained in (`_helpers.tpl`)[templates/_helpers.tpl] in `interpret-inner-gotpl`)

## Design notes

* no use case is identified to instantiate this chart multiple times in a
  given namespace, so this isn't supported (resource names aren't prefixed with the release name)

## TODO:

* to allow the `telco-cloud-init` release on the management cluster to be handled via GitOps, we need
  to generate it via a Kustomization (or HelmRelease) defined in the management cluster itself (instead of via a
  Kustomization defined in the bootstrap cluster with a kubeConfig pointing to mgmt cluster) - this will require
  adding an intermediate Kustomization to do that

* have flux handle itself in the management cluster (currently broken when a proxy is needed)

* allow use of `{{ .Values.xxx }}` in  some or all values (requires passing values into gotpl interpreter)  (?)

* add gitlab CI for the chart:
  * play `helm template` on a set of test `values.yaml` files
