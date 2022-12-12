
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
EOF

done
