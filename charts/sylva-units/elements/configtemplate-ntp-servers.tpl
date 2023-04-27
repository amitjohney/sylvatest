target:
  kind: |-
    {{ if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ConfigTemplate
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmConfigTemplate
    {{- end }}
patch: |-
  - op: add
    {{ if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    path: /spec/template/spec/agentConfig/ntp
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    path: /spec/template/spec/ntp
    {{- end }}
    value: {{ .Values.ntp | toJson }}

