{{/*
Common Annotations
*/}}
{{- define "cluster-api-vsphere.annotations" -}}
{{- if .Values.commonAnnotations }}
{{- toYaml .Values.commonAnnotations }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cluster-api-vsphere.labels" -}}
{{/* 
helm.sh/chart: {{ include "cluster-api-vsphere.chart" . }}
*/}}
{{ include "cluster-api-vsphere.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end }}

{{/*
Template for cluster name
*/}}
{{- define "cluster-api-vsphere.clusterName" -}}
{{- default .Release.Name .Values.cluster.name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "cluster-api-vsphere.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cluster-api-vsphere.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "cluster-api-vsphere.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create VSphereMachineControlPlaneTemplate name with sha256.
*/}}
{{- define "cluster-api-vsphere.VSphereMachineTemplateName" -}}
{{- (printf "%s-%s" .templatePrefix (include "cluster-api-vsphere.VSphereMachineTemplate" . | sha256sum)) | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Template for a VSphereMachineTemplate
*/}}
{{- define "cluster-api-vsphere.VSphereMachineTemplate" -}}
template:
  metadata:
    {{- if or (.templateValues.annotations) (include "cluster-api-vsphere.annotations" .) }}
    annotations:
      {{- if .templateValues.annotations }}
      {{- toYaml .templateValues.annotations | nindent 6 }}
      {{- end }}
      {{- if include "cluster-api-vsphere.annotations" . }}
      {{- include "cluster-api-vsphere.annotations" . | nindent 6 }}
      {{- end }}
    {{- end }}
    {{- if .Values.commonLabels }}
    labels: {{ toYaml .Values.commonLabels | nindent 6 }}
    {{- end }}
  spec:
    cloneMode: linkedClone
    datacenter: {{ .Values.vsphere.dataCenter }}
    datastore: {{ .templateValues.dataStore }}
    diskGiB: {{ .templateValues.diskSizeGiB }}
    folder: {{ .templateValues.folder }}
    memoryMiB: {{ .templateValues.memorySizeMiB }}
    network:
      devices:
      - networkName: {{ .Values.vsphere.network }}
        dhcp4: {{ .Values.machines.dhcp4 }}
        {{- if .templateValues.ipAddrs }}
          {{- if ne (len .templateValues.ipAddrs) 0 }}
        ipAddrs: {{ toYaml .templateValues.ipAddrs | nindent 8 }}
          {{- end }}
        {{- end }}
        {{- if ne (len .Values.machines.searchDomains) 0 }}
        searchDomains: {{ toYaml .Values.machines.searchDomains | nindent 8 }}
        {{- end }}
        {{- if .Values.machines.gateway }}
        gateway4: {{ .Values.machines.gateway }}
        {{- end }}
        {{- if  ne (len .Values.machines.nameServers) 0 }}
        nameservers: {{ toYaml .Values.machines.nameServers | nindent 8 }}
        {{- end }}
    numCPUs: {{ .templateValues.cpuCount }}
    resourcePool: {{ .templateValues.resourcePool }}
    server: {{ .Values.vsphere.server }}
    storagePolicyName: {{ .templateValues.storagePolicy }}
    template: {{ .templateValues.template }}
    thumbprint: {{ .Values.vsphere.tlsThumbprint }}
{{- end }}


{{/*
Create the chart kubeadm cluster configuration
*/}}
{{- define "cluster-api-vsphere.chart.kubeadm.clusterConfiguration" -}}
apiServer:
  certSANs:
    {{- if (.Values.kubernetes.kubeadm.controlPlane.clusterConfiguration.apiServer).certSANs }}
    {{- toYaml .Values.kubernetes.kubeadm.controlPlane.clusterConfiguration.apiServer.certSANs | nindent 4 }}
    {{- end }}
    - {{ .Values.cluster.controlPlaneEndpoint.host }}
  extraArgs:
    cloud-provider: external
    {{- if .Values.kubernetes.additionnalClientCaFile }}
    client-ca-file: /etc/kubernetes/pki/client_ca_full.pem
    {{- end }}
controllerManager:
  extraArgs:
    cloud-provider: external
{{- end }}

{{/*
Create the kubeadm cluster configuration
*/}}
{{- define "cluster-api-vsphere.kubeadm.clusterConfiguration" -}}
{{- $overrides := fromYaml (include "cluster-api-vsphere.chart.kubeadm.clusterConfiguration" .) | default (dict ) -}}
{{- toYaml (mergeOverwrite .Values.kubernetes.kubeadm.controlPlane.clusterConfiguration $overrides) -}}
{{- end }}

{{/*
Template for a KubeadmConfigTemplate
*/}}
{{- define "cluster-api-vsphere.KubeadmConfigTemplate" -}}
  template:
    spec:
      files:
    {{- if .Values.kubernetes.kubeadm.workers.files }}
      {{- toYaml .Values.kubernetes.kubeadm.workers.files | nindent 6 }}
    {{- end }}
    {{- if .templateValues.files }}
      {{- toYaml .templateValues.files | nindent 6 }}
    {{- end }}
      joinConfiguration:
        nodeRegistration:
          criSocket: {{ .templateValues.criSocket }}
          kubeletExtraArgs:
            cloud-provider: external
            {{- if .Values.kubernetes.kubeadm.commonKubeletExtraArgs }}
            {{- toYaml .Values.kubernetes.kubeadm.commonKubeletExtraArgs | nindent 12 }}
            {{- end }}
            {{- if .templateValues.kubeletExtraArgs }}
            {{- toYaml .templateValues.kubeletExtraArgs | nindent 12 }}
            {{- end }}
          name: '{{`{{ ds.meta_data.hostname }}`}}'
      preKubeadmCommands:
      - hostname "{{`{{ ds.meta_data.hostname }}`}}"
      - echo "::1         ipv6-localhost ipv6-loopback" >/etc/hosts
      - echo "127.0.0.1   localhost" >>/etc/hosts
      - echo "127.0.0.1   {{`{{ ds.meta_data.hostname }}`}}" >>/etc/hosts
      - echo "{{`{{ ds.meta_data.hostname }}`}}" >/etc/hostname
    {{- if .Values.kubernetes.kubeadm.workers.preKubeadmAdditionalCommands }}
      {{- toYaml .Values.kubernetes.kubeadm.workers.preKubeadmAdditionalCommands | nindent 6 }}
    {{- end }}
    {{- if .templateValues.preKubeadmAdditionalCommands }}
      {{- toYaml .templateValues.preKubeadmAdditionalCommands | nindent 6 }}
    {{- end }}
    {{- if or .Values.kubernetes.kubeadm.workers.postKubeadmAdditionalCommands .templateValues.postKubeadmAdditionalCommands }}
      postKubeadmCommands:
      {{- if .Values.kubernetes.kubeadm.workers.postKubeadmAdditionalCommands }}
      {{- toYaml .Values.kubernetes.kubeadm.workers.postKubeadmAdditionalCommands | nindent 6 }}
      {{- end }}
      {{- if .templateValues.postKubeadmAdditionalCommands }}
      {{- toYaml .templateValues.postKubeadmAdditionalCommands | nindent 6 }}
      {{- end }}
    {{- end }}
    {{- if .Values.machines.users }}
      users:
      {{- toYaml .Values.machines.users | nindent 6 }}
    {{- end }}
{{- end }}


{{/*
Create VSphereMachineControlPlaneTemplate name with sha256.
*/}}
{{- define "cluster-api-vsphere.KubeadmConfigTemplateName" -}}
{{- (printf "%s-%s" .templatePrefix (include "cluster-api-vsphere.KubeadmConfigTemplate" . | sha256sum)) | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

