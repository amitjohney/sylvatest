#!/usr/bin/env bash

cat <<EOF
include: '/.gitlab/ci/chart-jobs.yml'

stages:
  - test

EOF

for f in $(find charts/* -maxdepth 0 -type d)
do
cat <<EOF
'${f##*/}:helm-lint':
  stage: test
  extends: .helm-lint
  variables:
    HELM_NAME: "${f##*/}"
  rules:
    - changes:
        - ${f}/**/*
        - .gitlab/ci/**/*
  needs:
    - job: '${f##*/}:helm-schema-validation'
      optional: true

'${f##*/}:helm-yamllint':
  stage: test
  extends: .helm-yamllint
  variables:
    HELM_NAME: "${f##*/}"
  rules:
    - changes:
        - ${f}/**/*
        - .gitlab/ci/**/*

'${f##*/}:helm-template-yamllint':
  stage: test
  extends: .helm-template-yamllint
  variables:
    HELM_NAME: "${f##*/}"
  rules:
    - changes:
        - ${f}/**/*
        - .gitlab/ci/**/*
  needs:
    - job: '${f##*/}:helm-schema-validation'
      optional: true

'${f##*/}:helm-schema-validation':
  stage: test
  extends: .helm-schema-validation
  variables:
    HELM_NAME: "${f##*/}"
  rules:
    - exists:
        - charts/${f##*/}/values.schema.yaml
        - charts/${f##*/}/values.schema.json
      changes:
        - .gitlab/ci/**/*
        - charts/${f##*/}/values.schema.json
        - charts/${f##*/}/values.schema.yaml
        - charts/${f##*/}/values.yaml
        - tools/generate_json_schema.py
EOF

done

for f in $(find environment-values kustomize-units -type f -name 'kustomization.yaml' | grep -v '/ci/private/' | sed -r 's|/[^/]+$||')
do
cat <<EOF

'${f}:kustomize-build':
  stage: test
  extends: .kustomize-build
  variables:
    KUSTOMIZATION_PATH: "${f}"
  rules:
    - changes:
        - .gitlab/ci/**/*
        - environment-values/**/*
        - kustomize-units/**/*
EOF

done
