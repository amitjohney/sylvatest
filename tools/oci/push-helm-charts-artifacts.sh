#!/bin/bash
#
# This script will push helm charts used in sylva to registry.gitlab.com 
# as OCI registry artifacts.
#
#
# If run manually, the tool can be used after having preliminarily done
# a 'docker login registry.gitlab.com' with suitable credentials.
#
# Requirements:
# - helm
# - git

set -eu
set -o pipefail

BASE_DIR="$(realpath $(dirname $0)/../..)"
OCI_REGISTRY="${1:-oci://registry.gitlab.com/sylva-projects/sylva-core/}"
LOG_ERROR_FILE=$(mktemp)
VALUES_FILE="$BASE_DIR/charts/sylva-units/values.yaml"

# if we run in a gitlab CI job, then we use the credentials provided by gitlab job environment
if [[ -n ${CI_REGISTRY_USER:-} ]]; then
  creds="--creds $CI_REGISTRY_USER:$CI_REGISTRY_PASSWORD"
fi

function error {
  echo "[ERROR]"
  echo "The chart $1 has not been pushed to $OCI_REGISTRY" >> $LOG_ERROR_FILE
  echo $2 >> $LOG_ERROR_FILE
}

function process_chart_in_helm_repo {
  local helm_repo=$1
  local chart_name=$2
  local chart_version=$3
  local tgz_file="$chart_name-$chart_version.tgz"

  # Pull Helm chart locally
  if (helm pull --repo $helm_repo --version $chart_version $chart_name); then
    if [[ -e $tgz_file ]]; then
      # Push Helm chart to OCI
      helm push $tgz_file $OCI_REGISTRY
      rm -f $tgz_file
    else
      error $chart_name "The $tgz_file is not present after the 'helm pull' operation, check that the chart version is correct"
    fi
  else
    error $chart_name "The chart $chart_name:$chart_version from $helm_repo cant be pull locally"
  fi
}

function process_chart_in_git {
  local git_repo=$1
  local chart_path=$2
  local revision=$3
  local chart_name=$4
  local tgz_file="$chart_name-$revision.tgz"

  TMPD=$(mktemp -d)
  if (git clone -q --depth 1 --branch $revision $git_repo $TMPD > /dev/null 2>&1); then
    # Build locally Helm chart
    helm dep update $TMPD/$chart_path
    helm package --version $revision $TMPD/$chart_path
    if [[ -e $tgz_file ]]; then
      # Push Helm chart to OCI
      helm push "$tgz_file" $OCI_REGISTRY
      #flux push artifact $OCI_REGISTRY/$chart_name:$git_revision --path=$chart_path --source=$git_repo --revision=$git_revision ${creds:-}
    else
      error $chart_name "The $tgz_file is not present after the 'helm package' operation, check that the chart version is correct"
    fi
  else
    error $chart_name "The git repository $git_repo revision $git_revision cant be cloned"
  fi
  rm -rf $TMPD
}

function show_status {
  if [[ -s $LOG_ERROR_FILE ]]; then
    cat $LOG_ERROR_FILE
    rm -f $LOG_ERROR_FILE
    exit 1
  else
    echo "All Helm charts have been correctly synchronized to $OCI_REGISTRY"
  fi
}


### Helm registry login with credentials of Gitlab job environment
if [[ -n ${CI_REGISTRY_USER:-} ]]; then
    echo "$CI_REGISTRY_PASSWORD" | helm registry login -u $CI_REGISTRY_USER $CI_REGISTRY --password-stdin
fi

### Parse values file ###
readarray source_templates < <(yq -o=j -I=0 '.source_templates' $VALUES_FILE)
readarray units < <(yq -o=j -I=0 '.units[]' $VALUES_FILE)
for unit in "${units[@]}"; do
  helmrelease_spec=$(echo "$unit" | yq '.helmrelease_spec.chart.spec' -)
  if [[ -n "$helmrelease_spec" &&  $helmrelease_spec != "null" ]]; then
    chart=$(echo "$helmrelease_spec" | yq '.chart' -)
    helm_repo_url=$(echo "$unit" | yq '.helm_repo_url' -)
    if [[ -n "$helm_repo_url" && $helm_repo_url != "null" ]]; then
      ## Helm charts in helm repository ##
      version=$(echo "$helmrelease_spec" | yq '.version' -)
      process_chart_in_helm_repo $helm_repo_url $chart $version
    else
      ## Helm charts in git repository ##
      repo=$(echo "$unit" | yq '.repo')
      git_repo_url=$(echo "${source_templates[@]}" | yq ".$repo.spec.url" )
      git_revision=$(echo "${source_templates[@]}" | yq ".$repo.spec.ref.tag" )
      process_chart_in_git $git_repo_url $chart $git_revision $repo
    fi
  fi
done

show_status
