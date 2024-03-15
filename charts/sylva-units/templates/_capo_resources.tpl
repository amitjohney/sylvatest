{{- define "required_capo_resources" -}}
{{ /* 
returns a dict containing:
  - flavor name
  - replicas
for:
  - Control plane
  - each Machine deployment
*/}}
{{- $cp_replicas := .Values.cluster.control_plane_replicas }}
{{- $cp_flavor := .Values.cluster.capo.flavor_name | default "m1.large" }}
{{- $result := dict "CP" (dict "flavor" $cp_flavor "count" $cp_replicas )}}
{{- $result_mds := dict}}
{{- $md_default := .Values.cluster.machine_deployment_default}}
  {{- range $md, $config := .Values.cluster.machine_deployments -}}
    {{- $replicas := $config.replicas | $md_default.replicas }}
    {{- $flavor := $config.flavor_name | $md_default.capo.flavor_name }}
    {{- $_ := set $result_mds $md (dict "flavor" $flavor "replicas" $replicas) -}}
  {{- end -}}
{{- $_ := set $result "MDS" $result_mds }}
{{- $result | toJson }}
{{- end }}