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

SECONDS=0

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

function check_invalid_semver_tag {

  local version="$1"
  local rewrite_chart="${2:-}"
  if [[ "$version" =~ \.0[0-9] ]]; then
    # Implement a workaround for issue: https://gitlab.com/sylva-projects/sylva-core/-/issues/253 
    # If we find a version with a 0 prefix
    # rewrite the version by (a) prepeding a number before the z in x.y.z (for instance 9) 
    # and (b) keeping the original version in the free-form + field
    # 3.25.001 would become 3.25.9001+v3.25.001
    if [[ $version =~ (.?[0-9]+)\.([0-9]+)\.([0-9]+)([\+\-].*)? ]]; then
      major=${BASH_REMATCH[1]}
      medium=${BASH_REMATCH[2]}
      minor=${BASH_REMATCH[3]}
      others=${BASH_REMATCH[4]}
      new_version=$major.$medium.9$minor$others+$version    
      if [[ -n "$rewrite_chart" ]]; then
        tar -xzvf $tgz_file
        yq -i '.version = "'$new_version'"' $chart_name/Chart.yaml
        tar -czvf $chart_name-$new_version.tgz $chart_name/
        rm -rf $chart_name $tgz_file
        tgz_file="$chart_name-$new_version.tgz"
      fi
    fi
  fi

  echo "${new_version:-$version}"
}

function process_chart_in_helm_repo {
  local helm_repo=$1
  local chart_name=$2
  local chart_version=$3
  local tgz_file="$chart_name-$chart_version.tgz"

  # Pull Helm chart locally
  if (helm pull --repo $helm_repo --version $chart_version $chart_name); then
    if [[ -e $tgz_file ]]; then
      check_invalid_semver_tag $version true
      # Push Helm chart to OCI
      helm push $tgz_file $OCI_REGISTRY
      rm -f $tgz_file
    else
      if ls $chart_name*tgz >/dev/null 2>&1; then
        actual_chart=$(ls $chart_name*tgz)
        error $chart_name "The $tgz_file was expected but in fact $actual_chart was downloaded"
      else      
        error $chart_name "A $tgz_file file was expected, but no $chart_name*tgz file was produced by 'helm pull'."
      fi
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
    error $chart_name "The git repository $git_repo revision $revision cant be cloned"
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
  helmchart_spec=$(echo "$unit" | yq '.helmrelease_spec.chart.spec' -)
  if [[ -n "$helmchart_spec" &&  $helmchart_spec != "null" ]]; then
    chart=$(echo "$helmchart_spec" | yq '.chart' -)

    # no processing is needed if the chart is sylva-units
    # (sylva-units packaging is handled separately by build-sylva-units-artifact.sh)
    if [[ $chart =~ (^|/)sylva-units$ ]]; then
      echo "skipping sylva-units chart"
      continue
    fi

    helm_repo_url=$(echo "$unit" | yq '.helm_repo_url' -)
    if [[ -n "$helm_repo_url" && $helm_repo_url != "null" ]]; then
      ## Helm charts in helm repository ##
      version=$(echo "$helmchart_spec" | yq '.version' -)

      ## no processing is needed if the OCI artifact already exist in the OCI repository
      ## looking for invalid semver tag
      ## if an invalid tag is found we used a rewrited version of it for the check
      version_to_check=$(check_invalid_semver_tag $version)
      echo "Version to check: $version_to_check"
      if (flux pull artifact $OCI_REGISTRY/$chart:${version_to_check/+/_} -o /tmp 2>&1 || true) | grep -q created; then
        echo "Skipping $chart processing, $chart:$version_to_check already exists in $OCI_REGISTRY"
        continue
      fi

      process_chart_in_helm_repo $helm_repo_url $chart $version
    else
      ## Helm charts in git repository ##
      chart_name=$(echo "$unit" | yq '.helm_chart_artifact_name // ""')
      if [[ -z $chart_name ]]; then
        chart_name=$(echo "$helmchart_spec" | yq '.chart | sub(".*?([^/]+)$","${1}")')
      fi
      repo=$(echo "$unit" | yq '.repo')
      git_repo_url=$(echo "${source_templates[@]}" | yq ".$repo.spec.url" )
      git_revision=$(echo "${source_templates[@]}" | yq ".$repo.spec.ref.tag" )

      ## no processing is needed if the OCI artifact already exist in the OCI repository
      if (flux pull artifact $OCI_REGISTRY/$chart_name:${git_revision/+/_} -o /tmp 2>&1 || true) | grep -q created; then     
        echo "Skipping $chart_name processing, $chart_name:$git_revision already exists in $OCI_REGISTRY"
        continue
      fi

      process_chart_in_git $git_repo_url $chart $git_revision $chart_name
    fi
  fi
done

show_status

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
