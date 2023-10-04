{{/*
Ensure that no_proxy covers everything that we need by adding the values defined in no_proxy_base.
(Default values will be add only if the user set at least one of no_proxy or no_proxy_additional field) 
*/}}
{{- define "sylva-units.no_proxy" -}}
 {{- if or .Values.proxies.no_proxy .Values.no_proxy_additional }}
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
         {{- $no_proxy_list = append  $no_proxy_list $no_proxy_item  -}}
      {{- end -}}
   {{- end }}
   {{- append (splitList "," .Values.proxies.no_proxy)  ($no_proxy_list| join ",") | join "," | splitList ","| uniq | join "," }}
 {{- end }}
{{- end }}
