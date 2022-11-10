
This directory contains values that users must provide to control the deployment of the cluster.

It uses kustomisations to generate ConfigMaps and Secrets that will be passed to telco-cloud-init helm chart [helm-release.yaml](../kustomize-components/telco-cloud-init/base/helm-release.yaml) as override values over default chart [values.yaml](../charts/telco-cloud-init/values.yaml). These kustomisations are just provided as samples to help users to build resources that follow the expected format, feel free to build them to see how they lokk like (you can use `kubectl kustomize environment-values/kubeadm-capd` for example)

Various samples are provided for some supported environments, but they can be easily modified to adapt to your needs. Just keep in mind that these values will be merged over default values of the chart (as in json-merge, not strategic merge) so list/arrays will be overriden, for example.

Once generated, these manifests will be evaluated with envsubst by [bootstrap script](../bootstrap.sh) prior to being saved in configmap/management-cluster-values and secret/management-cluster-secrets resources. This substitution is just provided by convenience for some variables that may be substituted in several places in the context of bootstrap, but it is not intended to be used extensively, you are instead encouraged to provide values directly in these files.

The following variables will be substituted:

- `GITLAB_USER`
- `GITLAB_TOKEN`
- `CURRENT_COMMIT`
- `http_proxy`
- `https_proxy`
- `no_proxy`

Note that this whole directory is gitignored to make sure that custom configurations won't be committed by inadvertence. So if you intent to contribute to the project, make sure to use your own copy of values, this way your values and secrets can't be added to any changes by inadvertence. If you really intent to add files from that directory into git, use `git add -f` to add files to git index.
