target:
  kind: |-
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ConfigTemplate
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmConfigTemplate
    {{- end -}}
patch: |-
  {{- $provider := .Values.cluster.capi_providers.bootstrap_provider -}}
  {{- $registryMirrors := get .Values "registry_mirrors" | default dict -}}
  {{- $defaultSettings := get $registryMirrors "default_settings" | default dict -}}
  {{- range $registry, $mirrors := get $registryMirrors "hosts_config" | default dict }}
  - op: add
    path: /spec/template/spec/files/-
    value:
      path: /etc/containerd/registry.d/{{ $registry }}/hosts.toml
      owner: root
      permissions: "0644"
      content: |
        server = "https://{{ $registry }}"
        {{- range $_, $config := $mirrors }}
        [host."{{ $config.mirror_url }}"]
        {{- range $setting,$value := mergeOverwrite (deepCopy $defaultSettings) (get $config "registry_settings" | default dict) }}
          {{ $setting }} = {{ $value | toJson }}
        {{- end -}}
        {{- end -}}
        {{- end -}}
