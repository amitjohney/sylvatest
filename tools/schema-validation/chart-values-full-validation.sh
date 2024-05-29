#!/bin/bash
#
# Usage: sylva-units-values-full-validation.sh value-file1.yaml value-file2.yaml ...
#
# Validate that the value pass the chart Schema validation,
# **including after Helm GoTPL rendering** (which "helm template" or "helm install" won't do).

pushd $(dirname $0)/../..

set -opipefail

helm template charts/telco-cloud-init --show-only templates/telco-cloud-init-values-debug.yaml $(for values_file in $@; do echo "--values $values_file"; done) \
  | tools/yaml-merge.py /dev/stdin:/stringData/values -o json \
  | python -m jsonschema -o pretty charts/telco-cloud-init/values.schema.json -i /dev/stdin
