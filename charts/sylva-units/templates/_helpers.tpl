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

Function used to determine if a unit in 'units' (.Values.units dict) is
enabled based on the 'phase' and the .enabled value of the unit
(yes/no/management-only)

The default for <unit>.enabled is .Values.unit_default_enable .

Usage:

  tuple $envAll "unitFoo" | include "is-unit-enabled"

*/}}
{{- define "is-unit-enabled" -}}
    {{- $envAll := index . 0 -}}
    {{- $unit_name := index . 1 -}}
    {{- $unit_def := index $envAll.Values.units $unit_name -}}
    {{- $unit_enabled := toString $envAll.Values.unit_default_enable -}}
    {{- if hasKey $unit_def "enabled" -}}
      {{- $unit_enabled = toString $unit_def.enabled -}}
    {{- end -}}
    {{- $phase := $envAll.Values.phase -}}
    {{- if not (or (eq $phase "bootstrap") (eq $phase "management")) -}}
      {{- fail (printf "phase='%s' is neither 'bootstrap' or 'management'" $phase) -}}
    {{- end -}}
    {{- if (or (eq $unit_enabled "true")
               $envAll.Values.test_all_units_enabled
               (and (eq $unit_enabled "management-only") (eq $phase "management")))
    -}}
true
    {{- else if (or (eq ($unit_enabled) "false")
                    (and (eq $unit_enabled "management-only") (eq $phase "bootstrap"))) -}}{{/* we return an empty string to mean "false", this is a well-known trick for gotpl... */}}
    {{- else -}}
      {{- fail (printf "units.%s.enabled=%s is neither a boolean or 'management-only'" $unit_name $unit_enabled) -}}
    {{- end -}}
{{- end -}}



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
