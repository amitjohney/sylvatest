# sylva-units Helm charts

## Purpose

This chart deploys a set of sofware components called "units" on the current cluster.

The installation of those units is done thanks to FluxCD resources.

This chart key purpose in the Sylva stack is to coordinate the deployment of the software units
making up the Sylva stack, and to handle the instantiation of the management cluster thanks to
ClusterAPI.

The dependency resolution built-in FluxCD is used to orchestrate the creation of the management
cluster after installing the base units on the bootstrap cluster, which is then followed by
the deployments of units in the management cluster.

This chart also acts as the place where we handle "meta-release" aspect (ie. where we
determine the different versions to use))
and as a single entry point where the settings of a given Sylva deployment are defined.

## Not a typical Helm chart

While most Helm charts create Deployments/ConfigMaps/Service/etc to deploy a given service,
this chart does not do this at all, it instantiates only Flux resources that tell Flux how
to deploy our units.

These resources are:

* Kustomization resources, pointing to Git repositories in which kustomize `kustomization.yaml` and Kubernetes manifest files are defined describing how to deploy a unit
* HelmRelease resources, which contain definitions of Helm releases for Helm charts hosted for instance on Git (or in Helm repos) with the wanted overridden Helm values.

## What this chart does

When instantiating this chart on the bootstrap cluster, this chart will:

* install ClusterAPI and the desired providers, and their dependencies (e.g. cert-manager)
* install ClusterAPI definitions for the management cluster
* install Flux on the management cluster
* instantiate itself on the management cluster (step 2 below)

When instantiating this chart on the management cluster, this chart will:

* install Flux resources for the management of Flux itself (to allow managing Flux itself via GitOps)
* install ClusterAPI and the desired providers (and their dependencies)
* Flux definitions for any other unit to deploy on the management cluster (Rancher, security tools, monitoring tools, etc.)

When a "pivot" setup is wanted, where the management cluster manages its own ClusterAPI
lifecycle with GitOps, the following additional actions are done:

* the installation of the chart on the bootstrap cluster triggers a pivot operation once
  ClusterAPI units are installed on the management cluster
* the installation of the chart on the management cluster install Flux resources
  for the ClusterAPI definitions describing itself

## Usage

### Pre-requisite

Flux is already installed on the cluster on which the chart is being installed.

### Manual use of `helm`

* clone this repository

* ensure that FluxCD is installed on the local cluster

* prepare a file having the credentials needed to access Git repos (and GitLab Docker registry):

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
  capi_providers:
    infra_provider: capd
    bootstrap_provider: cabpr

units:
  capbr:
    enabled: true
  cappbr:
    enabled: true

  # this declares an override to deploy 'mydevbranch' branch
  # of https://gitlab.com/t6306/components/myunit.git/
  myunit:
    spec:
      ref:
        branch: mydevbranch

```

* install the Helm release (from this directory):

```
helm install sylva-units chart --values secrets.yaml --values myoverrides.yaml
```

### Use of a FluxCD HelmRelease

We have a convenient way of deploying this chart with a form of inheritance of "layers" of
Helm overrides, to allow deploying and maintaining different flavors/specialization/parametrizations
of Sylva, relying on kustomize overlays carrying the different layers that inject Helm
overrides into a FluxCD HelmRelease.

This is how this chart is used [in the context of this Git repository](../../environment-values/base/helm-release.yaml).

## Component definitions examples

To define a new unit, an entry can be added under `units` in values (either in `values.yaml` in the chart,
or in the values of the chart overriden for a given deployment flavor or for a given deployment).

### Component using a Kustomization defined in sylva-core repo

```yaml
units:

  my-unit:
    repo: sylva-core   # this refers to .git_repo_templates.sylva-core (defined in default values)
    kustomization_spec:
      path: ./kustomize-unit/myComponent
    depends_on:
      - name: my-other-unit  # my-unit will not be deployed before my-other-unit is ready
```

### Component using a Kustomization defined in another repository

```yaml
git_repo_templates:
  project-foo:
    spec:
      url: https://gitlab.com/t6306/components/foo.git

units:

  my-unit:
    repo: project-foo
    kustomization_spec:
      path: ./kustomize  # this will point to https://gitlab.com/t6306/components/foo.git / kustomize
```

### Component using a Helm chart defined in a Git repository

```yaml
git_repo_templates:
  helm-chart-bar:
    spec:
      url: https://gitlab.com/t6306/helm-charts/bar.git
      ref:
        tag: v1.0.3

units:

  my-unit:
    repo: helm-chart-bar
    helmrelease_spec:
      chart:
        spec:
          chart: ./my-chart   # this will point to https://gitlab.com/t6306/helm-charts/bar.git / my-chart  on tag v1.0.3
```

With this type of unit definition, Flux will reconciliate the HelmRelease based
on the Git revision (ignoring version field in the Helm chart `Chart.yaml` file).

### Component using a Helm chart defined in a Helm repository

```yaml
units:

  cert-manager:
    helm_repo_url: https://charts.jetstack.io
    helmrelease_spec:
      chart:
        spec:   # this will use v1.8.2 of the cert-manager chart found in the Helm repo at https://charts.jetstack.io
          chart: cert-manager
          version: v1.8.2
```

### How to feed settings coming from Helm values into the configuration of units

You can use Helm templating to feed settings coming from values into the configuration of your units:

```yaml
mgmt_cluster_domain_name: my-mgmt-cluster.foo.org

units:

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

As this feature is implemented using the helm templating function (aka "tpl") that only returns strings, you should pass it to the "preserve-type" template if want to prevent the result from being transformed to a string:

```yaml
git_auth_default:
  username: your_user_name
  password: glpat-XXXXX

git_repo_templates:
  sylva-core:
    spec:
      ...
    auth: '{{ .Values.git_auth_default | include "preserve-type" }}'
```

There is also a special "set-only-if" template that enable to conditionally add an item to a list or dict:

```yaml

port_list:
- 80
- '{{ tuple 443 .Values.enable_https | include "set-only-if" }}'

units:
  foo:
    # example of a conditional dependency
    depends_on:
    - '{{ tuple (dict "name" "bar") (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") | include "set-only-if" }}'
    helmrelease_spec:
      values:
        # set proxy value for foo chart only if proxies value contains an http_proxy key with a non-empty value
        proxy: '{{ tuple .Values.proxies.http_proxy .Values.proxies.http_proxy | include "set-only-if" }}'
```

For more details on templating features & limitations, refer to [`_interpret-values.tpl`](templates/_interpret-values.tpl)

## Design notes

* no use case is identified to instantiate this chart multiple times in a
  given namespace, so this isn't supported (resource names aren't prefixed with the release name)
