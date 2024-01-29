This directory contains GitLab-ci templates, scripts used to generate jobs and linter config files.

`scripts`: scripts used in CI
`configuration`: configuration files used in CI

Some `*_ADDITIONAL_VALUES` variables are available for specifying a file which defines some additional [**sylva-units**](../../charts/sylva-units) values that are merged on top of what we have in the environment-values directory used for a CI job (be it all in a local `values.yaml` or partly coming from a kustomization remote resource).

For context, since the job filesystem is cleaned between jobs (that's a GitLab CI principle), the contents of `$values_file` is not passed from one job to the next job in the same pipeline (for example the `update-workload-cluster` won't have the additional values passed by *yq merge* to `deploy-workload-cluster`).

That's why the following were implemented:

- `MGMT_ADDITIONAL_VALUES`: common base for the whole management cluster pipeline (deployment and update stages) values
- `MGMT_INITIAL_ADDITIONAL_VALUES`: values only for management cluster DEPLOYMENT job
- `MGMT_UPDATE_ADDITIONAL_VALUES`: values only for the management cluster UPDATE job

- `WC_ADDITIONAL_VALUES`: common base for the whole workload cluster pipeline (deployment and update stages) values
- `WC_INITIAL_ADDITIONAL_VALUES`: values only for workload cluster DEPLOYMENT job
- `WC_UPDATE_ADDITIONAL_VALUES`: values only for workload cluster UPDATE job
