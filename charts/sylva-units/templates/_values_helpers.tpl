{{/*
Ensure that no_proxy covers everything that we need by adding the values defined in no_proxy_base.
(Default values will be add only if the user set at least one of no_proxy or no_proxy_additional field) 
*/}}
{{- define "sylva-units.no_proxy" -}}
  {{- $envAll := . }}
  {{- $no_proxy_base  := dict
      "localhost" "true"
      ".svc" "true"
      (printf ".%s" .Values.cluster_external_domain) "true"
      ".cluster.local." "true"
      ".cluster.local" "true"
  -}}
  {{- $no_proxy_merged := mergeOverwrite $no_proxy_base .Values.no_proxy_additional -}}
  {{- $no_proxy_list := list -}}
  {{- range $no_proxy_item, $val := $no_proxy_merged -}}
    {{- if $val -}}
        {{- $no_proxy_list = append $no_proxy_list $no_proxy_item -}}
    {{- end -}}
  {{- end }}
  {{- range .Values.cluster.cluster_services_cidrs }}
    {{- $no_proxy_list = append $no_proxy_list . -}}
  {{- end }}
  {{- range .Values.cluster.cluster_pods_cidrs }}
    {{- $no_proxy_list = append $no_proxy_list . -}}
  {{- end }}
  {{- if .Values.cluster.capm3 }}
    {{- if .Values.cluster.capm3.public_pool_network -}}
      {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" .Values.cluster.capm3.public_pool_network .Values.cluster.capm3.public_pool_prefix) -}}
    {{- end -}}
    {{- if .Values.cluster.capm3.provisioning_pool_network -}}
      {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" .Values.cluster.capm3.provisioning_pool_network .Values.cluster.capm3.provisioning_pool_prefix) -}}
    {{- end -}}
    {{- range .Values.cluster.baremetal_hosts }}
      {{- $bmc_mgmt := urlParse (tuple $envAll .bmh_spec.bmc.address | include "interpret-as-string") }}
      {{- $no_proxy_list = append $no_proxy_list ($bmc_mgmt.host | splitList ":" | first) }}
    {{- end }}
  {{- end }}
  {{- $no_proxy_list = concat $no_proxy_list (splitList "," .Values.proxies.no_proxy) -}}
  {{- without $no_proxy_list "" | uniq | join "," }}
{{- end }}
