target:
  kind: |-
    {{ if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ControlPlane
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmControlPlane
    {{- end }}
patch: |-
  - op: add
    {{ if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    path: /spec/agentConfig/ntp
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    path: /spec/kubeadmConfigSpec/ntp
    {{- end }}
    value: {{ .Values.ntp | toJson }}
