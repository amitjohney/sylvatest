{{- define "generate-os-images" -}}
osImages:
{{- $sylva_dib_images := .Values.sylva_diskimagebuilder_images }}
{{- $sylva_dib_version := .Values.sylva_diskimagebuilder_version }}
{{- $os_images_oci_registries := .Values.os_images_oci_registries }}
{{- $os_images := .Values.os_images }}
{{- if (.Values.os_images) }}
  {{- range $os_image_name, $os_image_props := .Values.os_images }}
  {{ $os_image_name }}:
    {{- range $prop_key, $prop_value := $os_image_props }}
    {{ $prop_key }}: {{ $prop_value | quote }}
    {{- end }}
  {{- end }}
{{- end }}
  {{- range $os_image_name, $os_image_props := $sylva_dib_images }}
    {{- if (or ($os_image_props.enabled) (and $os_image_props.default_enabled (not $os_images ))) }}
  {{ $os_image_name }}:
    {{- $os_image_props := mergeOverwrite (dict "os_images_oci_registry" "sylva") $os_image_props }}
    {{- $oci_registry_url := dig $os_image_props.os_images_oci_registry "url" "" $os_images_oci_registries }}
    {{- $oci_registry_tag := dig $os_image_props.os_images_oci_registry "tag" "" $os_images_oci_registries }}
    uri: '{{ $oci_registry_url }}/{{ $os_image_name }}:{{ $oci_registry_tag }}'
    sylva_dib_image: true
    {{- end }}
  {{- end }}
{{- end }}
