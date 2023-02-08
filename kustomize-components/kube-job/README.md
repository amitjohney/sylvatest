# kube-job

This job is intended to be run as a Flux Kustomization that will overload the content of kube-job.sh.

It is can be used (with moderation) to introduce some specific jobs in flux dependency chart, when they can not be done in other way. For example, we may use it to copy secrets and configs or to perform cluster-api pivot from bootstrap to managent cluster.

```
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  # ...ommitted for brevity
  patches:
    - patch: |-
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: job-scripts
          namespace: default
        data:
          kube-job.sh: |
            #!/bin/sh
            kubectl get pods
```
