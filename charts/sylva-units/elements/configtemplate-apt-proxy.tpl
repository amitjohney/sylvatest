target:
  kind: |-
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ConfigTemplate
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmConfigTemplate
    {{- end -}}
patch: |-
  - op: add
    path: /spec/template/spec/files/-
    value:
      path: /etc/apt/apt.conf.d/proxy.conf
      owner: root
      permissions: "0644"
      content: |
        Acquire::http::Proxy {{ .Values.proxies.http_proxy | quote -}};
        Acquire::https::Proxy {{ .Values.proxies.https_proxy | quote -}};
