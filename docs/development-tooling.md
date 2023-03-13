# Development tooling

Some of the scripts run in  Sylva's CI can also be run manually on developer laptop to help during the development process

## Helm schema validation

To validate that the schema of one of Sylva charts is a valid JSONSchema, you can run the following script:

`tools/gci-templates/scripts/helm-schema-validation.sh sylva-units`

pre-requisites:

* helm
* yamllint
* Python3
* jsonschema Python module
* curl

## Helm template lint

To perform test runs of `helm template` followed by the YAML validation of the output, (with default and tests values) for one of Sylva Helm charts, you can run the following script:

`tools/gci-templates/scripts/helm-template-yamllint.sh sylva-units`

pre-requisites:

* helm
* yamllint
* yq
