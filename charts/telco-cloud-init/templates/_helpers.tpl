{{/*
Expand the name of the chart.
*/}}
{{- define "telco-cloud-init.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "telco-cloud-init.fullname" -}}
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
{{- define "telco-cloud-init.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "telco-cloud-init.selectorLabels" -}}
app.kubernetes.io/name: {{ include "telco-cloud-init.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "telco-cloud-init.labels" -}}
helm.sh/chart: {{ include "telco-cloud-init.chart" . }}
{{ include "telco-cloud-init.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*

Function used to determine if a component in 'components' (.Values.components dict) is
enabled based on the 'phase' and the .enabled value of the component
(yes/no/management-only)

The default for <component>.enabled is .Values.component_default_enable .

Usage:

  tuple $envAll "componentFoo" | include "is-component-enabled"

*/}}
{{- define "is-component-enabled" -}}
    {{- $envAll := index . 0 -}}
    {{- $component_name := index . 1 -}}
    {{- $component_def := index $envAll.Values.components $component_name -}}
    {{- $component_enabled := toString $envAll.Values.component_default_enable -}}
    {{- if hasKey $component_def "enabled" -}}
      {{- $component_enabled = toString $component_def.enabled -}}  
    {{- end -}}
    {{- $phase := $envAll.Values.phase -}}
    {{- if not (or (eq $phase "bootstrap") (eq $phase "management")) -}}
      {{- fail (printf "phase='%s' is neither 'bootstrap' or 'management'" $phase) -}}
    {{- end -}}
    {{- if (or (eq $component_enabled "true")
               (and (eq $component_enabled "management-only") (eq $phase "management")))
    -}}
true
    {{- else if (or (eq ($component_enabled) "false")
                    (and (eq $component_enabled "management-only") (eq $phase "bootstrap"))) -}}{{/* we return an empty string to mean "false", this is a well-known trick for gotpl... */}}
    {{- else -}}
      {{- fail (printf "components.%s.enabled=%s is neither a boolean or 'management-only'" $component_name $component_enabled) -}}
    {{- end -}}
{{- end -}}



{{/*

This is used by components.yaml to patch the HelmRelease
resource produced when the kustomization from kustomize-components/helmrelease-generic
which is used to create a Flux Kustomization that generates a HelmRelease.

*/}}
{{ define "helmrelease-kustomization-patch-template" }}
{{- $component_name := index . 0 -}}
{{- $helmrelease_spec := index . 1 -}}
{{- $labels := index . 2 -}}
target:
  kind: HelmRelease
patch: |
  - op: replace
    path: /metadata
    value:
      namespace: default
      name: {{ $component_name }}
      labels:
{{ $labels | toYaml | indent 8 }}
  - op: replace
    path: /spec
    value: 
{{ $helmrelease_spec | toYaml | indent 6 }}
{{ end }}

{{/*

interpret-inner-gotpl

This is used to interpret any '{{ .. }}' templating found
in a datastructure, doing that on all strings found at the
different levels.

This template returns the resulting datastructure
marshalled as a JSON dict {"result": ...}

Usage:

    tuple $envAll $data | include "interpret-inner-gotpl"

Example:

    $data := dict "foo" (dict "bar" "{{ .Values.bar }}")
    index (tuple $envAll $data | include "interpret-inner-gotpl" | fromJson) "result"

Values:

    bar: something here

Result:

    {"foo": {"bar": "something here"}}


Note well that there are a few limitations:

* there is no error management on templating:

    foo: 42
    x: "{{ .Values.fooo }}"  -> x after processing by this template will give "" (nothing complains about 'fooo' not being defined)

* the templating that you use cannot currently return anything else than a string.

    foo: 42
    x: "{{ .Values.foo }}"  -> x after processing by this template will give "42" not 42

    bar:
     - 1
     - 2
     - 3
    y: "{{ .Values.bar }}"  -> y after processing by this template will give '[1 2 3]', which is not what you want (not a list of numbers)

* everything looking like "{{ }}" will be interpreted, even non-gotpl stuff
  that you might want to try to put in your manifest because a given component
  would need that

*/}}
{{ define "interpret-inner-gotpl" }}
    {{ $envAll := index . 0 }}
    {{ $data := index . 1 }}
    {{ $kind := kindOf $data }}
    {{ $result := 0 }}
    {{ if (eq $kind "string") }}
        {{ if contains "{{" $data }}
            {{/* This is where we actually trigger GoTPL interpretation */}}
            {{ $result = tpl $data $envAll }}
        {{ else }}
            {{ $result = $data }}
        {{ end }}
    {{ else if (eq $kind "slice") }}
        {{/* this is a list, recurse on each item */}}
        {{ $result = list }}
        {{ range $data }}
            {{ $result = append $result (index (tuple $envAll . | include "interpret-inner-gotpl" | fromJson) "result") }}
        {{ end }}
    {{ else if (eq $kind "map") }}
        {{/* this is a dictionary, recurse on each key-value pair */}}
        {{ $result = dict }}
        {{ range $key,$value := $data }}
            {{ $_ := set $result (index (tuple $envAll $key | include "interpret-inner-gotpl" | fromJson) "result") (index (tuple $envAll $value | include "interpret-inner-gotpl" | fromJson) "result") }}
        {{ end }}
    {{ else }}  {{/* bool, int, float64 */}}
        {{ $result = $data }}
    {{ end }}

{{ dict "result" $result | toJson }}
{{ end }}
