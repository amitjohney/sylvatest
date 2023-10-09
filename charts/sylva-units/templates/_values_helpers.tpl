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
   {{- range .Values.cluster.cluster_services_cidrs }}
     {{- $no_proxy_list = append $no_proxy_list . -}}
   {{- end }}
   {{- range .Values.cluster.cluster_pods_cidrs }}
     {{- $no_proxy_list = append $no_proxy_list . -}}
   {{- end }}
   {{- if .Values.cluster.capm3 }}
     {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" .Values.cluster.capm3.public_pool_network .Values.cluster.capm3.public_pool_prefix) -}}
     {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" .Values.cluster.capm3.provisioning_pool_network .Values.cluster.capm3.provisioning_pool_prefix) -}}
     {{- range .Values.cluster.baremetal_hosts }}
       {{- $bmc_mgmt := urlParse .bmh_spec.bmc.address }}
       {{- $no_proxy_list = append $no_proxy_list ($bmc_mgmt.host | splitList ":" | first) }}
     {{- end }}
   {{- end }}
   {{- if and (tuple . "workload-cluster" | include "unit-enabled") (eq (index .Values.units "workload-cluster" "helmrelease_spec" "values" "cluster" "capi_providers" "infra_provider") "capm3") }}
     {{- $workload_public_network := index .Values.units "workload-cluster" "helmrelease_spec" "values" "cluster" "capm3" "public_pool_network" -}}
     {{- $workload_public_prefix := index .Values.units "workload-cluster" "helmrelease_spec" "values" "cluster" "capm3" "public_pool_prefix" -}}
     {{- if and $workload_public_network $workload_public_prefix }}
       {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" $workload_public_network $workload_public_prefix) -}}
     {{- end }}
     {{- $workload_prov_network := index .Values.units "workload-cluster" "helmrelease_spec" "values" "cluster" "capm3" "provisioning_pool_network" -}}
     {{- $workload_prov_prefix := index .Values.units "workload-cluster" "helmrelease_spec" "values" "cluster" "capm3" "provisioning_pool_prefix" -}}
     {{- if and $workload_prov_network $workload_prov_prefix }}
       {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" $workload_prov_network $workload_prov_prefix) -}}
     {{- end }}
   {{- end }}
   {{- append (splitList "," .Values.proxies.no_proxy) ($no_proxy_list| join ",") | join "," | splitList ","| uniq | join "," }}
 {{- end }}
{{- end }}
