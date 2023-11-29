# kube-job

This job is intended to be run as a Flux Kustomization that will overload the content of `kube-job.sh`.

This can be used (with moderation) to introduce some specific jobs in flux dependency chain, when they can not be done in other way. For example, we may use it to copy secrets and configs or to perform cluster-api pivot from bootstrap to management cluster.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo
  namespace: flux-system
spec:
  postBuild:
    substitute:
      JOB_NAME: podinfo-job
      JOB_TARGET_NAMESPACE: kube-job
      MY_VAR: my_value
  patches:
    - target:
        kind: ConfigMap
      patch: |
        - op: replace
          path: /data/kube-job.sh
          value: |
            #!/bin/bash
            kubectl get pods
            echo ${MY_VAR}
```

Note: as explained in Flux documentation [here](https://fluxcd.io/flux/components/kustomize/kustomizations/#post-build-variable-substitution),
if you want to avoid var substitutions in scripts embedded in ConfigMaps or container commands,
you must use the format $var instead of ${var}. If you want to keep the curly braces you can use $${var} which will print out ${var}.
