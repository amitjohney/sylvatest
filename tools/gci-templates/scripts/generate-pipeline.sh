#!/usr/bin/env bash

cat <<EOF
include: '/tools/gci-templates/gitlab-ci.yml'

stages:
  - test
  - security-test

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
        - tools/gci-templates/**/*
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
        - tools/gci-templates/**/*

'${f##*/}:helm-template-yamllint':
  stage: test
  extends: .helm-template-yamllint
  variables:
    HELM_NAME: "${f##*/}"
  rules:
    - changes:
        - ${f}/**/*
        - tools/gci-templates/**/*
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
        - tools/gci-templates/**/*
        - charts/${f##*/}/values.schema.json
        - charts/${f##*/}/values.schema.yaml
        - tools/generate_json_schema.py
EOF

done

for f in $(find environment-values kustomize-units -type f -name 'kustomization.yaml' | sed -r 's|/[^/]+$||')
do
cat <<EOF

'${f}:kustomize-build':
  stage: test
  extends: .kustomize-build
  variables:
    KUSTOMIZATION_PATH: "${f}"
  rules:
    - changes:
        - tools/gci-templates/**/*
        - environment-values/**/*
        - kustomize-units/**/*


'${f}:kube-score':
  stage: security-test
  extends: .kube-score
  variables:
    KUSTOMIZATION_PATH: "${f}"
  rules:
    - changes:
        - tools/gci-templates/**/*
        - environment-values/**/*
        - kustomize-units/**/*
EOF

done
