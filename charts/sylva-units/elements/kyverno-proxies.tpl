kustomize:
  patchesStrategicMerge:
    - kind: Deployment
      apiVersion: apps/v1
      metadata:
        name: kyverno-admission-controller
        namespace: kyverno
      spec:
        template:
         spec:
           containers:
             - name: kyverno
               env:
               - name: HTTPS_PROXY
                 value: '{{ .Values.proxies.https_proxy }}'
               - name: NO_PROXY
                 value: '{{ include "sylva-units.no_proxy" . }}'
