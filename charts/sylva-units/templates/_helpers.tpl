{{/*
Expand the name of the chart.
*/}}
{{- define "sylva-units.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sylva-units.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sylva-units.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "sylva-units.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sylva-units.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sylva-units.labels" -}}
helm.sh/chart: {{ include "sylva-units.chart" . }}
{{ include "sylva-units.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*

This is used by units.yaml to patch the HelmRelease
resource produced when the kustomization from kustomize-units/helmrelease-generic
which is used to create a Flux Kustomization that generates a HelmRelease.

*/}}
{{ define "helmrelease-kustomization-patch-template" }}
  {{- $unit_name := index . 0 -}}
  {{- $helmrelease_spec := index . 1 -}}
  {{- $labels := index . 2 -}}
  {{- $has_secret := index . 3 -}}
patches:
  - target:
      kind: HelmRelease
    patch: |
      - op: replace
        path: /metadata
        value:
          namespace: default
          name: {{ $unit_name }}
          labels: {{ $labels | toYaml | nindent 12 }}
      - op: replace
        path: /spec
        value: {{ mergeOverwrite (dict "valuesFrom" list) $helmrelease_spec | toYaml | nindent 10 }}
  {{ if $has_secret }}
  - target:
      kind: Secret
    patch: |
      - op: replace
        path: /metadata
        value:
          namespace: default
          name: helm-unit-values-{{ $unit_name }}
          labels: {{ $labels | toYaml | nindent 12 }}
  - target:
      kind: HelmRelease
    patch: |
      - op: add
        path: /spec/valuesFrom/0
        value:
          kind: Secret
          name: helm-unit-values-{{ $unit_name }}
          valuesKey: values
  {{ else }}
  - target:
      kind: Secret
    patch: |
      kind: Secret
      metadata:
        name: _unused_
      $patch: delete
  {{ end }}
{{ end }}


{{/*

Test if a unit is enabled or not

Usage:

{{ if tuple $envAll "unit-name" | include "unit-enabled" }}

*/}}
{{- define "unit-enabled" -}}
  {{- $envAll := index . 0 -}}
  {{- $unit_name := index . 1 -}}

  {{- $unit_enabled := $envAll.Values.units_enabled_default -}}

  {{- $unit_def := index $envAll.Values.units $unit_name -}}
  {{- if $unit_def -}}
    {{- if hasKey $envAll.Values "units_override_enabled" -}}
      {{- $interpreted_units_override_enabled := index (tuple $envAll $envAll.Values.units_override_enabled | include "interpret-inner-gotpl" | fromJson) "result" -}}
      {{- $unit_enabled = has $unit_name $interpreted_units_override_enabled -}}
    {{- else if hasKey $unit_def "enabled" -}}
      {{- $unit_enabled = index (tuple $envAll $unit_def.enabled (printf "unit:%s" $unit_name) | include "interpret-as-bool" | fromJson) "encapsulated-result" -}}
    {{- end -}}

    {{- range $condition := $unit_def.enabled_conditions | default list -}}
      {{- $unit_enabled = and $unit_enabled (index (tuple $envAll $condition (printf "unit:%s" $unit_name) | include "interpret-as-bool" | fromJson) "encapsulated-result") -}}
      {{- if not $unit_enabled -}}
        {{- break -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- if or $unit_enabled $envAll.Values.all_units_enabled  -}}
true
  {{- else -}} {{- /* we "emulate" a 'false' value by returning an empty string which the caller will evaluate as False */ -}}
  {{- end -}}
{{- end -}}
