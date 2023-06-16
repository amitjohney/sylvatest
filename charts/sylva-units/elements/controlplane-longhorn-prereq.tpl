target:
  kind: |-
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") -}}
    RKE2ControlPlane
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") -}}
    KubeadmControlPlane
    {{- end }}
patch: |-
  - op: add
    {{- if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpr") }}
    path: /spec/preRKE2Commands/-
    {{- else if (eq .Values.cluster.capi_providers.bootstrap_provider "cabpk") }}
    path: /spec/kubeadmConfigSpec/preKubeadmCommands/-
    {{- end }}
    value: apt-get update ; apt install -y open-iscsi nfs-common

