
This directory contains values that users must provide to control the deployment of the cluster.

It uses kustomisations to generate ConfigMaps and Secrets that will be passed to telco-cloud-init helm chart [helm-release.yaml](../kustomize-components/telco-cloud-init/base/helm-release.yaml) as override values over default chart [values.yaml](../charts/telco-cloud-init/values.yaml). These kustomisations are just provided as samples to help users to build resources that follow the expected format, feel free to build them to see how they lokk like (you can use `kubectl kustomize environment-values/kubeadm-capd` for example)

Various samples are provided for some supported environments, but they can be easily modified to adapt to your needs. Just keep in mind that these values will be merged by helm over default values of the chart (as in json-merge, not strategic merge) so list/arrays will be overriden, for example:

```
CHART VALUES.YAML:
ports_list:
  - 80
  - 443
USER-SUPPLIED VALUES:
ports_list:
  - 8080
  - 8443
COMPUTED VALUES:
ports_list:
  - 8080
  - 8443
```

You must also pay attention to null values, as helm interprets them as an [instrution to delete the corresponding key](https://helm.sh/docs/chart_template_guide/values_files/#deleting-a-default-key), which is fairly different from typical dict merge behaviour:

```
CHART VALUES.YAML:
proxies:
  http_proxy: ""
  https_proxy: ""
USER-SUPPLIED VALUES:
proxies:
  http_proxy:
  https_proxy:
COMPUTED VALUES:
proxies: {}
```

Once generated, these manifests will be evaluated with envsubst by [bootstrap script](../bootstrap.sh) prior to being saved in configmap/management-cluster-values and secret/management-cluster-secrets resources. This substitution is just provided by convenience for some variables that may be substituted in several places in the context of bootstrap, but it is not intended to be used extensively, you are instead encouraged to provide values directly in these files.

The following variables will be substituted:

- `GITLAB_USER`
- `GITLAB_TOKEN`
