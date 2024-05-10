{{/*
Ensure that no_proxy covers everything that we need by adding the values defined in no_proxy_base.
(Default values will be add only if the user set at least one of no_proxy or no_proxy_additional field) 
*/}}
{{- define "sylva-units.no_proxy" -}}
  {{- $envAll := index . 0 -}}

  {{/* this function accepts an optional second parameter to override entries from no_proxy_additional) */}}
  {{- $overrides := dict -}}
  {{- if gt (len .) 1 -}}
      {{- $overrides = index . 1 -}}
  {{- end -}}

  {{/* we start building the list of no_proxy items, accumulating them in $no_proxy_list... */}}
  {{- $no_proxy_list := concat $envAll.Values.cluster.cluster_pods_cidrs $envAll.Values.cluster.cluster_services_cidrs -}}
  {{- if $envAll.Values.cluster.capm3 -}}
    {{- if $envAll.Values.cluster.capm3.primary_pool_network -}}
      {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" $envAll.Values.cluster.capm3.primary_pool_network $envAll.Values.cluster.capm3.primary_pool_prefix) -}}
    {{- end -}}
    {{- if $envAll.Values.cluster.capm3.provisioning_pool_network -}}
      {{- $no_proxy_list = append $no_proxy_list (printf "%s/%s" $envAll.Values.cluster.capm3.provisioning_pool_network $envAll.Values.cluster.capm3.provisioning_pool_prefix) -}}
    {{- end -}}
    {{- range $envAll.Values.cluster.baremetal_hosts -}}
      {{- $bmc_mgmt := urlParse (tuple $envAll .bmh_spec.bmc.address | include "interpret-as-string") -}}
      {{- $no_proxy_list = append $no_proxy_list ($bmc_mgmt.host | splitList ":" | first) -}}
    {{- end -}}
  {{- end -}}

  {{- $no_proxy_list = concat $no_proxy_list (splitList "," $envAll.Values.proxies.no_proxy) -}}

  {{/* we merge 'no_proxy_additional_rendered' with 'overrides'
       note well that we do this after *interpreting* any go templating
  */}}
  {{- $no_proxy_additional_rendered := dict -}}
  {{- range $no_proxy_item,$val := $envAll.Values.no_proxy_additional -}}
    {{- $_ := set $no_proxy_additional_rendered (tuple $envAll $no_proxy_item | include "interpret-as-string") $val -}}
  {{- end -}}
  {{- range $no_proxy_item,$val := $overrides -}}
    {{- $_ := set $no_proxy_additional_rendered (tuple $envAll $no_proxy_item | include "interpret-as-string") $val -}}
  {{- end -}}

  {{/* we add to the list the no_proxy items that are enabled
       and remove the disabled ones
  */}}
  {{- range $no_proxy_item, $val := $no_proxy_additional_rendered -}}
    {{- if $val -}}
      {{- $no_proxy_list = append $no_proxy_list $no_proxy_item -}}
    {{- else -}}
      {{- $no_proxy_list = without $no_proxy_list $no_proxy_item -}}
    {{- end -}}
  {{- end -}}

  {{/* render final list */}}
  {{- without $no_proxy_list "" | uniq | join "," -}}
{{- end -}}

{{/*
Define the field sylvaUnitsSource that is used in sylva-units-release-template.
This field is defined differently according to the deployment type.
*/}}
{{- define "surT-default" -}}
 {{- $envAll := . -}}
 {{- if eq (index .Values.source_templates "sylva-core" "kind") "OCIRepository" -}}
type: oci
url: {{ .Values.sylva_core_oci_registry }}
tag: {{ .Values._internal.sylva_core_version }}
 {{- else -}}
   {{- $sylva_spec := dict -}}
   {{- $sylva_spec = (lookup "source.toolkit.fluxcd.io/v1beta2" "GitRepository" "sylva-system" "sylva-core" | dig "spec" "") -}}
type: git
   {{- if $sylva_spec }}
url: {{ $sylva_spec.url }}
     {{- if $sylva_spec.ref.commit }}
commit: {{ $sylva_spec.ref.commit }}
     {{- else if $sylva_spec.ref.tag }}
tag: {{ $sylva_spec.ref.tag }}
     {{- else }}
branch: {{ $sylva_spec.ref.branch }}
     {{- end }}
   {{- else }}
url: https://gitlab.com/sylva-projects/sylva-core.git
branch: main
   {{- end }}
 {{- end -}}
{{- end -}}

{{/*
Have the (first paramenter) dict structure traversed by dig for each element of an input list (second parameter)

usage: |
  tuple (dict "foo1" (dict "bar1" "toto1") "foo2" (dict "bar2" (dict "titi2" "toto2"))) (list "foo1" "bar1")         | include "recursive-dig" # returns toto1
  tuple (dict "foo1" (dict "bar1" "toto1") "foo2" (dict "bar2" (dict "titi2" "toto2"))) (list "foo2" "bar2" "titi2") | include "recursive-dig" # returns toto2

*/}}
{{- define "recursive-dig" -}}
  {{- $checked_dict := index . 0 -}}
  {{- $dig_values_list := index . 1 -}}
  {{- range $i := $dig_values_list }}
    {{- $checked_dict = $checked_dict | dig $i "" | default dict -}}
  {{- end -}}
  {{- $checked_dict }}
{{- end -}}

{{/*
Return an error if the upgrade values (passed as list of dict keys) are not equal to previous revision set
*/}}
{{- define "enforce-immutable" -}}
  {{- $envAll := index . 0 -}}
  {{- $dig_values_list := index . 1 -}}
  {{- $current_value := tuple ($envAll.Values | merge (dict)) $dig_values_list | include "recursive-dig" -}}
  {{- $debug_secret_values := lookup "v1" "Secret" $envAll.Release.Namespace "sylva-units-values"| dig "data" "values" "" | b64dec | fromYaml | default dict -}}

  {{/* only check if Secret/sylva-units-values contents is not empty map */}}
  {{- if $debug_secret_values -}}
    {{- $initial_value := tuple $debug_secret_values $dig_values_list | include "recursive-dig" }}
    {{- if not (deepEqual $initial_value  $current_value)  -}}
      {{- fail (printf "The %s value provided initially (%s) is different than the currently provided one (%s)" (join "." $dig_values_list) $initial_value $current_value) -}}
    {{- end -}}
  {{- end -}}
  {{- $current_value -}}
{{- end -}}
