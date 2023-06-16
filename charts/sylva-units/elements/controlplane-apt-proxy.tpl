target:
  kind: |-
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ControlPlane
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmControlPlane
    {{- end -}}
patch: |-
  - op: add
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") }}
    path: /spec/files/-
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") }}
    path: /spec/kubeadmConfigSpec/files/-
    {{- end }}
    value:
      path: /etc/apt/apt.conf.d/proxy.conf
      owner: root
      permissions: "0644"
      content: |
        Acquire::http::Proxy {{ .Values.proxies.http_proxy | quote -}};
        Acquire::https::Proxy {{ .Values.proxies.https_proxy | quote -}};
