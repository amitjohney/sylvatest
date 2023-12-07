# Introduction

This guide aims to provide an overview of the CI/CD chain used by Sylva projects.

Today, the aim of the CI chain is to ensure good code quality, deploy, and test Sylva in multiple environments.

Supported deployment types:

* capd using a generic GitLab.com runner
* capo using dedicated runners, they deploy Sylva on top of an OpenStack platform (Orange side)
* cam3-virt using dedicated Equinix runners

We are trying to keep the code maintainable and without too much code duplication. We achieve that with the usage of templates and extends.
Project Structure

This section describes the file structure we use to organize our CI.

`.gitlab-ci.yml`

This file is the main entry point, from which we'll include both remote and local templates.

The `.gitlab/ci/` folder contains all the local files used in Sylva CI.

```shell
.
├── chart-jobs.yml
├── child-pipeline-default.yml
├── common.yml
├── configuration/
│   ├── yamllint-helm-exclude-charts.yaml
│   ├── yamllint-helm-exclude-chart-templates.yaml
│   ├── yamllint-helm-template-rules
│   └── yamllint.yaml
├── main-pipeline-builds.yml
├── main-pipeline-checks.yml
├── main-pipeline-cleanup.yml
├── main-pipeline-deployment-tests.yml
├── main-pipeline-workflow-and-globals.yml
├── pipeline-deploy-capo.yml
├── pipeline-deploy-kubeadm-capd.yml
├── pipeline-deploy-rke2-capm3-virt-equinix.yml
├── README.md
├── scripts/
│   ├── generate-pipeline.sh
│   └── units-reports.py
└── templates-deployments.yml
```

Under this folder, you'll find:

configuration folder containing all the configuration files used by our tooling (mainly linter configuration files) scripts folder containing all the scripts specific to the CI

Then, the files are organized with the following prefixes:

`main-pipeline-*` are the files included by `.gitlab-ci.yml`. We split them per stage.

 ```shell

    ├── main-pipeline-builds.yml                # Build OCI artifact
    ├── main-pipeline-checks.yml                # Run linters
    ├── main-pipeline-cleanup.yml               # Scheduled cleanup for CAPO deployment
    ├── main-pipeline-deployment-tests.yml      # Run all deployments
    ├── main-pipeline-workflow-and-globals.yml  # Define global workflow and common variables
```

* `templates-*` contain templates used by other pipelines.
* `child-pipeline-default.yml` contains configuration common to all child pipelines used by deployments (like stages, workflow, etc.).
* `pipeline-deploy-*` define a given deployment pipeline.

## Deployment pipelines

For deployment, we use child pipelines. From `.gitlab/ci/main-pipeline-deployment-tests.yml`, we trigger them using a trigger include of a `pipeline-deploy-*` file and some variables to customize it.

```yaml
capo-fip-deploy:
  extends: .default-trigger-oci
  variables:
    ENV_NAME: kubeadm-capo
    CAPO_TAG: "${ENV_TAG_OCI}-fip"
    CUSTOM_VALUES_FILE: environment-values/ci/capo-fip.yml
    MGMT_WATCH_TIMEOUT_MIN: 20
    ONLY_DEPLOY_MGMT: "TRUE"
    E2E_JOB_MR_PARITY: none
  trigger:
    include: .gitlab/ci/pipeline-deploy-capo.yml
    strategy: depend
```

Most of our deployment pipelines are manual jobs.

CAPO-based pipelines can only be started by a subset of people. CAPD & CAPM3 pipelines can be started by any Sylva-core developers.

## Contribution guideline
