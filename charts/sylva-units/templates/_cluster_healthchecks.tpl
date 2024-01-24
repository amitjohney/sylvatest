{{/*

cluster-healthchecks

This named template generates the content of healthChecks field for a Flux CD Kustomization, with
reference to CAPI resources for the current CAPI cluster defined in the 'cluster' unit, with the
'sylva-capi-cluster' chart.

The background is that:
* the HelmRelease resource instantiating sylva-capi-cluster has no health check (FluxCD HelmReleases don't have that)
* we hence want to do the checks in the Kustomization that creates that HelmRelease
* the list of resource cannot be static, because it depends on:
  - which control plane provider is used
  - which infra provider is used
  - what are the machine deployments defined

Depending on the context, this template can be used to generate the references to the MachineDeployments or not.

This is because in the kubeadm case we can't wait for the MachineDeployemts in "cluster" unit, or this prevents
deploying the CNI, and the CNI itself is needed before the MachineDeployment nodes can be considered ready by CAPI.

*/}}

{{ define "cluster-healthchecks" }}

{{- $ns := .ns -}}  {{/* this corresponds to .Release.Namespace */}}
{{- $cluster := .cluster -}}  {{/* this corresponds to .Values.cluster */}}
{{- $includeMDs := . | dig "includeMDs" true -}}

{{/* the healtchecks is a list, we wrap it into a dict to overcome the
     fact that fromYaml can't return anything else than a dict
*/}}
result:

{{/*

Wait for Cluster resource:

*/}}

    - apiVersion: cluster.x-k8s.io/v1beta1
      kind: Cluster
      name: {{ $cluster.name }}
      namespace: {{ $ns }}

{{/*

Wait for infra provider Cluster

*/}}

{{- $cluster_k := lookup "apiextensions.k8s.io/v1" "customresourcedefinition.apiextensions.k8s.io" "" "clusters.cluster.x-k8s.io" -}}
{{- if $cluster_k }}
{{- $cluster_kind := lookup "cluster.x-k8s.io/v1beta1" "Cluster" $ns $cluster.name | dig "spec" "infrastructureRef" "kind" "" -}}
{{- $cluster_apiVersion := lookup "cluster.x-k8s.io/v1beta1" "Cluster" $ns $cluster.name | dig "spec" "infrastructureRef" "apiVersion" "" -}}

    - apiVersion: {{ $cluster_apiVersion }}
      kind: {{ $cluster_kind }}
      name: {{ $cluster.name }}
      namespace: {{ $ns }}

{{/*

We determine which control plane object to look at depending
on the CAPI bootstrap provider being used.

*/}}

{{- $cp_kind := lookup "cluster.x-k8s.io/v1beta1" "Cluster" $ns $cluster.name | dig "spec" "controlPlaneRef" "kind" "" -}}
{{- $cp_apiVersion := lookup "cluster.x-k8s.io/v1beta1" "Cluster" $ns $cluster.name | dig "spec" "controlPlaneRef" "apiVersion" "" -}}

    - apiVersion: {{ $cp_apiVersion }}
      kind: {{ $cp_kind }}
      name: {{ $cluster.name }}-control-plane
      namespace: {{ $ns }}

{{/*

If $includeMDs was specified, we include all the MachineDeployments in the healthChecks.

*/}}

{{ if $includeMDs -}}
    {{- range $md_name,$_ := $cluster.machine_deployments }}
    - apiVersion: cluster.x-k8s.io/v1beta1
      kind: MachineDeployment
      name: {{ $cluster.name }}-{{ $md_name }}
      namespace: {{ $ns }}
    {{ end -}}
{{- end -}}

{{/*

All the above is subject to a race condition: if Flux checks the status too early
it concludes, because CAPI resources aren't fully kstatus compliant, that the resource is ready

Waiting for the cluster kubeconfig Secret is a workaround

*/}}

    - apiVersion: v1
      kind: Secret
      name: {{ $cluster.name }}-kubeconfig
      namespace: {{ $ns }}

{{ if .sleep_job }}
    - apiVersion: batch/v1
      kind: Job
      name: dummy-deps-cluster-ready-sleep
      namespace: kube-job
{{ end }}
{{ end }}
{{ end -}}
