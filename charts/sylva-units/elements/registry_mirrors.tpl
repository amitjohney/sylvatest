target:
  kind: |-
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ControlPlane
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmControlPlane
    {{- end -}}
patch: |-
  {{- $provider := .Values.cluster.capi_providers.bootstrap_provider -}}
  {{- $registryMirrors := get .Values "registry_mirrors" | default dict -}}
  {{- $defaultSettings := get $registryMirrors "default_settings" | default dict -}}
  {{- range $registry, $mirrors := get $registryMirrors "hosts_config" | default dict }}
  - op: add
    {{- if (eq $provider "cabpk") }}
    path: /spec/kubeadmConfigSpec/files/-
    {{- else if (eq $provider "cabpr") }}
    path: /spec/files/-
    {{- else -}}
    {{- fail (printf "unsupported bootstrap_provider: '%s'" $provider) -}}
    {{- end }}
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
