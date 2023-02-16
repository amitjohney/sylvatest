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
target:
  kind: HelmRelease
patch: |
  - op: replace
    path: /metadata
    value:
      namespace: default
      name: {{ $unit_name }}
      labels:
{{ $labels | toYaml | indent 8 }}
  - op: replace
    path: /spec
    value:
{{ $helmrelease_spec | toYaml | indent 6 }}
{{ end }}


{{/*

Test if a unit is enabled or not

Usage:

{{ if tuple $envAll "unit-name" | include "unit-enabled" }}

*/}}
{{ define "unit-enabled" }}
  {{- $envAll := index . 0 -}}
  {{- $unit_name := index . 1 -}}

  {{- $unit_enabled := false -}}

  {{- if hasKey $envAll.Values "units_override_enabled" -}}
      {{- $unit_enabled = has $unit_name $envAll.Values.units_override_enabled -}}
  {{- else -}}
      {{- $unit_def := index $envAll.Values.units $unit_name -}}
      {{- if $unit_def -}}
          {{- $unit_enabled = dig "enabled" true $unit_def -}}
      {{- end -}}
  {{- end -}}

  {{- if not (kindIs "bool" $unit_enabled) -}}
    {{- fail (printf "units.%s.enabled is not a boolean (is a %s: %s)" $unit_name (kindOf $unit_enabled) $unit_enabled) -}}
  {{- end -}}

  {{- if $unit_enabled -}}
true
  {{- else -}}
  {{- end -}}
{{ end }}
