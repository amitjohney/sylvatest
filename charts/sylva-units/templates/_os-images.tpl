{{- define "images_from_os_images"}}
{{- /* returns a dict of images + properties if images defined in 
  bootstrap_os_images_override_enabled list match images defined in os_images dict
  else returns an empty dict */}}
{{- $images := dict }}
{{- $bootstrap_images := .Values._internal._bootstrap_os_images_override_enabled | toStrings -}}
{{- /*
.Values._internal._bootstrap_os_images_override_enabled is seen has a slice, we cast it to list of strings
*/}}
  {{- if (.Values.os_images) }}
    {{- range $os_image_name, $os_image_props := .Values.os_images }}
      {{- if (or (not $bootstrap_images) (and $bootstrap_images (has $os_image_name $bootstrap_images))) }}
        {{- $_ := set $images $os_image_name $os_image_props }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- $images | toJson }}
{{- end }}


{{- define "images_from_diskimagebuilder" }}
{{- /* returns a dict of images + properties (uri + sylva_dib_image) if images defined in 
  bootstrap_os_images_override_enabled list match images defined in sylva_diskimagebuilder_images
  else returns an empty dict */}}
{{- $images := dict }}
{{- $bootstrap_images := .Values._internal._bootstrap_os_images_override_enabled | toStrings -}}
{{- /*
.Values._internal._bootstrap_os_images_override_enabled is seen has a slice, we cast it to list of strings
*/}}
{{- $sylva_dib_images := .Values.sylva_diskimagebuilder_images }}
{{- $sylva_dib_version := .Values.sylva_diskimagebuilder_version }}
{{- $os_images_oci_registries := .Values.os_images_oci_registries }}
{{- $os_images := .Values.os_images }}
  {{- range $os_image_name, $os_image_props := $sylva_dib_images }}
  {{- $os_image_props := mergeOverwrite (dict "os_images_oci_registry" "sylva") $os_image_props }}
  {{- $oci_registry_url := dig $os_image_props.os_images_oci_registry "url" "" $os_images_oci_registries }}
  {{- $oci_registry_tag := dig $os_image_props.os_images_oci_registry "tag" "" $os_images_oci_registries }}
    {{- if ($bootstrap_images) }}
      {{- if (has $os_image_name $bootstrap_images) }}
        {{- $os_image_props := mergeOverwrite (dict "os_images_oci_registry" "sylva") $os_image_props }}
        {{- $uri := printf "%s/%s:%s" $oci_registry_url $os_image_name $oci_registry_tag }}
        {{- $props := dict "uri" $uri "sylva_dib_image" true }}
        {{- $_ := set $images $os_image_name $props }}
      {{- end }}
    {{- else if (or ($os_image_props.enabled) (and $os_image_props.default_enabled (not $os_images ))) }}
        {{- $uri := printf "%s/%s:%s" $oci_registry_url $os_image_name $oci_registry_tag }}
        {{- $props := dict "uri" $uri "sylva_dib_image" true }}
        {{- $_ := set $images $os_image_name $props }}
    {{- end }}
  {{- end }}
{{- $images | toJson }}
{{- end }}

{{- define "check_all_images_override_exist" }}
{{- /* verify all images defined in bootstrap_os_images_override_enabled correspond 
to an image name defined in either .Values.os_images or .Values.sylva_diskimagebuilder_images
if successful return nothing else fails with a human understandable error message */}}
{{- $errors := list }}
{{- $bootstrap_images := .Values._internal._bootstrap_os_images_override_enabled | toStrings -}}
{{- $sylva_dib_images := .Values.sylva_diskimagebuilder_images }}
{{- $os_images := .Values.os_images }}
  {{- range $bootstrap_images }}
    {{- if and (not (hasKey $os_images . )) (not (hasKey $sylva_dib_images .)) }}
      {{- $error := printf "OS image %s is specified in bootstrap_os_images_override_enabled but is not defined in neither .Values.sylva_diskimagebuilder_images nor .Values.os_images" .}}
      {{- $errors = append $errors $error }}
    {{- end }}
  {{- end }}
{{ dict "errors" $errors | toJson }}
{{- end }}

{{- define "generate-os-images" -}}
{{- $bootstrap_images := .Values._internal._bootstrap_os_images_override_enabled | toStrings -}}
os_images:
{{- $images_from_os_images := include "images_from_os_images" . | fromJson }}
  {{- if $images_from_os_images }}
{{ $images_from_os_images | toYaml | indent 2}}
  {{- end }}
{{- $images_from_diskimagebuilder := include "images_from_diskimagebuilder" . | fromJson }}
  {{- if $images_from_diskimagebuilder }}
{{ $images_from_diskimagebuilder | toYaml | indent 2}}
  {{- end }}
  {{- if and (not $images_from_os_images) (not $images_from_diskimagebuilder) }}
{{ dict | toYaml }}
  {{- end }}
{{- $errors := include "check_all_images_override_exist" . | fromJson }}
  {{- if (gt (get $errors "errors" | len ) 0) }}
    {{- range (get $errors "errors")}}
# error: {{.}}
    {{- end }}
{{- end }}
{{- end }}

