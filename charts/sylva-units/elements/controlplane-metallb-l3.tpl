target:
  kind: |-
    RKE2ControlPlane
patch: |-
  - op: add
    path: /spec/files/-
    value:
      path: /var/lib/rancher/rke2/server/manifests/metallb-l3.yaml
      owner: root
      permissions: "0644"
      content: |
      {{- range .Values.cluster.metallb_additional_options.address_pools }}
        ---
        apiVersion: metallb.io/v1beta1
        kind: IPAddressPool
        metadata:
          name: {{ .name }}
          namespace: metallb-system
        spec:
          addresses: {{ .addresses | toYaml | nindent 8 }}
      {{- end -}}
      {{- range .Values.cluster.metallb_additional_options.l3_options.bgp_peers }}
        ---
        apiVersion: metallb.io/v1beta2
        kind: BGPPeer
        metadata:
          name: {{ .name }}
          namespace: metallb-system
        spec:
          myASN: {{ .local_asn }}
          peerASN: {{ .peer_asn }}
          peerAddress: {{ .peer_address }}
        ---
        apiVersion: metallb.io/v1beta1
        kind: BGPAdvertisement
        metadata:
          name: {{ .name }}
          namespace: metallb-system
        spec:
          ipAddressPools:
          {{- range .advertised_pools }}
            - {{ . }}
          {{- end }}
          peers:
          - {{ .name }}
      {{- end }}
