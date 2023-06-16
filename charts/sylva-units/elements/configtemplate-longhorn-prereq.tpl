target:
  kind: |-
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ConfigTemplate
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmConfigTemplate
    {{- end }}
patch: |-
  - op: add
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") }}
    path: /spec/template/spec/preRKE2Commands/-
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") }}
    path: /spec/template/spec/preKubeadmCommands/-
    {{- end }}
    value: apt-get update ; apt install -y open-iscsi nfs-common
