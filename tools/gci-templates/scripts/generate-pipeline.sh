
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

'${f##*/}:helm-yamllint':
  stage: test
  extends: .helm-yamllint
  variables:
    HELM_NAME: "${f##*/}"
  rules:
    - changes:
        - ${f}/**/*

EOF

done
