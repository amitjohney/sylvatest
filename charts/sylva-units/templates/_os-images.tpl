{{- define "generate-os-images" -}}
{{- $cluster := "boostrap" -}}
{{- $cp_image := "" -}}
{{- if (.Values.cluster.capi_providers.infra_provider | eq "capm3") -}}
  {{- $cp_image = get .Values.cluster.capm3 "image_key" | default "none" -}}
{{- else if (.Values.cluster.capi_providers.infra_provider | eq "capo") -}}
  {{- $cp_image = get .Values.cluster.capo "image_key" | default "none" -}}
{{- end -}}
osImages:
{{- $sylva_dib_images := .Values.sylva_diskimagebuilder_images }}
{{- $sylva_dib_version := .Values.sylva_diskimagebuilder_version }}
{{- $sylva_base_oci_registry := (tuple . .Values.sylva_base_oci_registry | include "interpret-as-string") }}
{{- if (.Values.os_images) }}
  {{- range $os_image_name, $os_image_props := .Values.os_images }}
  {{ $os_image_name }}:
    {{- range $prop_key, $prop_value := $os_image_props }}
    {{ $prop_key }}: {{ $prop_value | quote }}
    {{- end }}
  {{- end }}
  {{- range $os_image_name, $os_image_props := $sylva_dib_images }}
    {{- if ($os_image_props.enabled) }}
  {{ $os_image_name }}:
    uri: {{ $sylva_base_oci_registry }}/sylva-elements/diskimage-builder/{{ $os_image_name }}:{{ $sylva_dib_version }}
    {{- end }}
  {{- end }}
{{- else }}
  {{- range $os_image_name, $os_image_props := $sylva_dib_images }}
    {{- if (or ($os_image_props.enabled) ($os_image_props.default_enabled)) }}
      {{- if (eq $cp_image $os_image_name) }}
  {{ $os_image_name }}:
    uri: {{ $sylva_base_oci_registry }}/sylva-elements/diskimage-builder/{{ $os_image_name }}:{{ $sylva_dib_version }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
