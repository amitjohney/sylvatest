#!/usr/bin/env bash

cat <<EOF
default:
  tags:
    - gitlab-org-docker
  image: registry.gitlab.com/sylva-projects/sylva-elements/container-images/ci-image:v1-0-4

stages:
 - deploy
 - units-testing

.unit-tests:
  stage: units-testing
  artifacts:
    paths:
      - results/
  rules:
    - if: \$CI_PIPELINE_SOURCE == "parent_pipeline"

EOF

for f in $(find kustomize-units/*/unit-tests -maxdepth 0 -type d)
do
  cat $f/*.yaml
done