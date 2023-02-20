#!/usr/bin/env bash

cat <<EOF
include: '/tools/gci-templates/gitlab-ci.yml'

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
        - tools/yaml2json.py
EOF

done

for f in $(find environment-values kustomize-units -type f -name 'kustomization.yaml' | sed -r 's|/[^/]+$||')
do
  # Here we'll look into environment-values & kustomize-units for kustomization.yaml files which contains relative paths (../something).
  # If we found theses kind of paths we'll expand them to create paths relative to the main git repo folder and append them with **/* suffix
  # Theses paths will be added to the changes: section, so the .kustomize-build job will be run either if the kustomization.yaml file is changed
  # or if any of his local dependencies changes too.
  dependencies_path=''
  current_path=$(pwd)
  cd $current_path/${f}
  dependencies_path=$(yq -r '.resources[] |select(. == "../*")' kustomization.yaml | xargs -r -I % readlink -f % | sed "s/${current_path//\//\\/}\///g" | sed 's/^/        - /g' | sed "s/$/\/**\/*/g")
  cd $current_path
cat <<EOF

'${f}:kustomize-build':
  stage: test
  extends: .kustomize-build
  variables:
    KUSTOMIZATION_PATH: "${f}"
  rules:
    - changes:
        - ${f}/**/*
        - tools/gci-templates/**/*
$dependencies_path
EOF

done