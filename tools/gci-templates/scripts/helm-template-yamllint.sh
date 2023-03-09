#!/usr/bin/env bash

set -o pipefail

HELM_NAME=${HELM_NAME:-$1}

if [[ -z ${HELM_NAME} ]]; then
  echo "Missing parameter.

  This script expect to find either:
  
  HELM_NAME environment variable defined with the name of the chart to validate

  or the name of the chart to validate pass as a parameter.

  helm-template-yamllint.sh sylva-units

  "
  exit 1
fi

function helm() { $(which helm) $@ 2> >(grep -v 'found symbolic link' >&2); }

export BASE_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")/../../.." ; pwd -P )

chart_dir=${BASE_DIR}/charts/${HELM_NAME}

echo -e "\e[0Ksection_start:`date +%s`:helm_dependency_build\r\e[0K--------------- helm dependency build"

helm dependency build $chart_dir

echo -e "\e[0Ksection_end:`date +%s`:helm_dependency_build\r\e[0K"

echo -e "\e[0Ksection_start:`date +%s`:helm_base_values\r\e[0K--------------- Checking default values with 'helm template' and 'yamllint' (for sylva-units chart all units enabled) ..."

# This applies only to sylva-units chart where we want to check that templating
# works fine with all units enabled
yq eval '{"units": .units | ... comments="" | to_entries | map({"key":.key,"value":{"enabled":true}}) | from_entries}' $chart_dir/values.yaml > /tmp/all-units-enabled.yaml

helm template ${HELM_NAME} $chart_dir --values /tmp/all-units-enabled.yaml \
| yamllint - -d "$(cat < ${BASE_DIR}/tools/gci-templates/yamllint.yaml) $(cat < ${BASE_DIR}/tools/gci-templates/yamllint-helm-template-rules)"

echo OK
echo -e "\e[0Ksection_end:`date +%s`:helm_base_values\r\e[0K"

test_dirs=$(find $chart_dir/test-values -mindepth 1 -maxdepth 1 -type d)
if [ -d $chart_dir/test-values ] && [ -n "$test_dirs" ] ; then
  for dir in $test_dirs ; do
    echo -e "\e[0Ksection_start:`date +%s`:helm_more_values\r\e[0K--------------- Checking values from test-values/$(basename $dir) with 'helm template' and 'yamllint' ..."

    set +e
    helm template ${HELM_NAME} $chart_dir $(ls $dir/*.y*ml | grep -v test-spec.yaml | sed -e 's/^/--values /') \
      | yamllint - -d "$(cat < ${BASE_DIR}/tools/gci-templates/yamllint.yaml) $(cat < ${BASE_DIR}/tools/gci-templates/yamllint-helm-template-rules)"
    exit_code=$?
    set -e

    if [[ -f $dir/test-spec.yaml && $(yq .require-failure $dir/test-spec.yaml) == "true" ]]; then
        expected_exit_code=1
        error_message="This testcase is supposed to make 'helm template ..| yamllint ..' fail, but it actually succeeded."
        success_message="This negative testcase expectedly made 'helm template ..| yamllint ..' fail."
    else
        expected_exit_code=0
        error_message="Failure when running 'helm template ..| yamllint ..' on this test case."
    fi

    if [[ $exit_code -ne $expected_exit_code ]]; then
      echo $error_message
      exit
    else
      echo $success_message
    fi

    echo OK
    echo -e "\e[0Ksection_end:`date +%s`:helm_more_values\r\e[0K"
  done
fi
