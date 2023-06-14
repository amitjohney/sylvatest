target:
  kind: OpenStackMachineTemplate
  labelSelector: role=control-plane
patch: |
  {{- range .Values.cluster.metallb_additional_options.address_pools }}
  {{- range .addresses }}
  {{- if regexMatch "^[0-9.]*-[0-9.]*$" . }}
  {{- $range := split "-" . }}
  {{- $firstIPBits := split "." $range._0 }}
  {{- $lastIPBits := split "." $range._1 }}
  {{- range untilStep ($firstIPBits._3 | int) ($lastIPBits._3 | add1 | int) 1 }}
  - op: add
    path: /spec/template/spec/ports/0/allowedAddressPairs/-
    value:
      ipAddress: {{ $firstIPBits._0 }}.{{ $firstIPBits._1 }}.{{ $firstIPBits._2 }}.{{ . }}
  {{- end }}
  {{- else }}
  - op: add
    path: /spec/template/spec/ports/0/allowedAddressPairs/-
    value:
      ipAddress: {{ . }}
  {{- end }}
  {{- end }}
  {{- end }}
