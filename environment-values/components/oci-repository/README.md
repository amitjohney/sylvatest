To use this component, you'll need to set the `ref.tag` field to the tag that you want
to use for the `kustomize-units` OCI registry artifact (`registry.gitlab.com/sylva-projects/sylva-core/kustomize-units`).

The possible tags for this artifact are the tags of the `sylva-core` Git repo itself.

The `registry.gitlab.com/sylva-projects/sylva-core/kustomize-units` registry can be
accessed at [here](https://gitlab.com/sylva-projects/sylva-core/container_registry/4011022):

```yaml
components:
  - ../path/to/environment-values/components/oci-repository

patches:
- target:
    kind: OCIRepository
    name: sylva-core
  patch: |
    - op: replace
      path: /spec/ref/tag
      value: test-tmorin   ## <<< the tag you want to use
```
