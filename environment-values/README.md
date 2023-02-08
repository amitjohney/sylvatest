
This directory contains user-provided values to control the deployment of the cluster.

It uses kustomisations to genrate ConfigMaps and Secrets that will be passed to telco-cloud-init helm chart [helm-release.yaml](../kustomize-components/telco-cloud-init/base/helm-release.yaml) as override values over default chart [values.yaml](../charts/telco-cloud-init/values.yaml).

Various samples are provided for supported environment, but they can be easely modified or copied to adapt to your needs. Just keep in mind that these values will be merged over default values of the chart (as in json-merge, not strategic merge) so list/arrays will be overriden for example.

Once genereated, these manifests will be evaluated with envsubst by [bootstrap script](../bootstrap.sh) prior to being saved in configmap/management-cluster-values and secret/management-cluster-secrets resources. Following variables will be substituted:

- `GITLAB_USER`
- `GITLAB_TOKEN`
- `CURRENT_COMMIT`
- `http_proxy`
- `https_proxy`
- `no_proxy`

Note that this whole directory is gitignored to make sure that custom configurations won't be committed by inadvertence, so please use `git add -f` if you intent to commit changes here.
