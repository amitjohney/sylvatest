target:
  kind: ConfigMap
  name: coredns
patch: |-
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: not-used
  data:
    Corefile: |
      ${CLUSTER_EXTERNAL_DOMAIN}:53 {
          errors
          {{- if .Values.cluster.capo.floating_ip -}}
          hosts {
              {{ .Values.cluster.capo.floating_ip }} rancher.sylva
              fallthrough
          }
          {{- end -}}
          forward ${CLUSTER_EXTERNAL_DOMAIN} ${CLUSTER_EXTERNAL_IP}
      }
      .:53 {
          errors
          health {
            lameduck 5s
          }
          ready
          kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
          }
          prometheus :9153
          forward . /etc/resolv.conf {
            max_concurrent 1000
          }
          cache 30
          loop
          reload
          loadbalance
      }
