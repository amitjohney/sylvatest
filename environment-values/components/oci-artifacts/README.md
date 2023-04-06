This component prepares the `sylva-units` `HelmRelease` and the associated
resources to deploy Sylva based solely on OCI artifacts (instead
of fetching manifests, kustomize-based software from Git, and Helm charts
from a mix of Helm repos and Git repos).

To use this component, you'll need to add patches in your environment values
`kustomization.yaml` to have the OCIRegistry and HelmRelease point to the
version of sylva-core that you want to deploy.

The possible tags for these artifact are the tags of the `sylva-core` Git repo itself.

The `registry.gitlab.com/sylva-projects/sylva-core` registry can be
accessed at [here](https://gitlab.com/sylva-projects/sylva-core/container_registry:

Example:

```yaml
components:
  - path/to/environment-values/components/oci-artifacts

patches:
- target:
    kind: OCIRepository
    name: sylva-core
  patch: |
    - op: replace
      path: /spec/ref/tag
      value: 0.0.0-test   ## <<< the tag you want to use
- target:
    kind: HelmRelease
    name: sylva-units
  patch: |
    - op: replace
      path: /spec/chart/spec/version
      value: 0.0.0-test   ## <<< the tag you want to use
```
