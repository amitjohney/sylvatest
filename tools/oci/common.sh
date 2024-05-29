#!/bin/bash
#
# This script will push helm charts used in sylva to registry.gitlab.com 
# as OCI registry artifacts.
#
#
# If run manually, the tool can be used after having preliminarily done
# a 'docker login registry.gitlab.com' with suitable credentials.
#
# To enable signing when running manually, export the environment variables:
# - COSIGN_PASSWORD
# - COSIGN_PRIVATE_KEY (in PEM format)
#
# Cosign default signing material is available on sylva project gitlab://43786055
#
# Requirements:
# - helm
# - git
# - cosign

OCI_REGISTRY="${OCI_REGISTRY:-oci://registry.gitlab.com/sylva-projects/sylva-core/}"
FORCE_HELM_CHART_PROCESSING=${FORCE_HELM_CHART_PROCESSING:-false}  # can be set to "true" to force OCI artifact sign&push even it they already exist
REGISTRY_URI="${OCI_REGISTRY/oci:\/\//}"

function error {
  echo "[ERROR]"
  echo "The chart $1 has not been pushed to $OCI_REGISTRY" >> $LOG_ERROR_FILE
  echo $2 >> $LOG_ERROR_FILE
}

function artifact_integrity {
  local tgz_file=$1
  local artifact_name=$2
  local artifact_version=$3

  artifact_url=$OCI_REGISTRY/$artifact_name:${artifact_version}

  pull_artifact_dir=$(mktemp -d -t pull-artifacts-XXXXXX)

  echo "flux pull artifact $artifact_url -o $pull_artifact_dir"
  # The integrity test makes sense only if the OCI artifact exists
  if (flux pull artifact $artifact_url -o $pull_artifact_dir); then
    echo "Checking the integrity of the existing unsigned artifact $artifact_name:${artifact_version} :: $artifact_url"
    pulled_name=$(ls $pull_artifact_dir)  # to handle situation where artifact is renamed e.g. s/core/neuvector-core
    tmp_dir=$(mktemp -d /tmp/tgz-XXXXXXX)
    tar -xzvf $tgz_file -C $tmp_dir
    echo "---------- make a diff --------------"
    find $pull_artifact_dir -name Chart.lock -type f -delete
    find $pull_artifact_dir -depth -name .git -type d -exec rm -rv {} +
    diff -qr $pull_artifact_dir/$pulled_name $tmp_dir/$pulled_name
  fi
}

function push_and_sign {
 
      local tgz_file=$1
      local artifact_name=$2
      local artifact_version=$3
      local artifact_type=$4

      if !(artifact_integrity $tgz_file $artifact_name $artifact_version); then
        echo "[ERROR] cannot push and sign $artifact_name because its content differs from the content of the already existing OCI artifact"
        return 1
      fi
      digest=""
      if [[ $artifact_type == "helm" ]];then
        helm push $tgz_file $OCI_REGISTRY >output 2>&1
        digest=$(grep 'Digest:' output | sed 's/^.*: //')
      else
        flux push artifact $OCI_REGISTRY/$artifact_name:$artifact_version \
                --path=${processed_kustomize_units:-.} \
                --source=$artifact_source \
                --revision=$artifact_revision \
                ${creds:-} >/tmp/output 2>&1
        digest=$(grep '@' /tmp/output | sed 's/^.*@//')
      fi
      if [[ -v COSIGN_PRIVATE_KEY ]] && [[ -v COSIGN_PASSWORD ]]; then
      # Sign the artifact, it adds a new tag
         cosign sign -y --tlog-upload=false --key  env://COSIGN_PRIVATE_KEY  "$REGISTRY_URI/${artifact_name}@${digest}"
      fi
      rm -f /tmp/output
}

function can_skip_artifact_push {
  # if the environment variable FORCE_HELM_CHART_PROCESSING is set to true, the helm chart is processed even if it exists
  if [[ $FORCE_HELM_CHART_PROCESSING == "true" ]]; then
          echo "Force processing artifact $1 ..."
          return 1
  fi

  echo "Checking if artifact $1 exists..."

  if (flux pull artifact $1 -o /tmp); then
    # artifact exists
     if [[ -v COSIGN_PRIVATE_KEY ]] && [[ -v COSIGN_PASSWORD ]]; then
       artifact_uri=$(echo $1 | sed 's/oci:\/\///')
       echo "Check if artifact $artifact_uri is signed with the correct key"
       if cosign verify --insecure-ignore-tlog=true --key env://COSIGN_PUBLIC_KEY $artifact_uri; then
         echo "Artifact $artifact_uri exists and is already signed with the correct key, skipping it"
         # Don't process the artifact if it exists and properly signed
         return 0
       else
         echo "Artifact $artifact_uri exists and needs to be signed"
         return 1
       fi
     fi
     # artifact exists and no signing material available
     return 0
  else
    # artifact does no exist
    return 1
  fi

}

if ! [[ -v COSIGN_PRIVATE_KEY ]]; then
   echo "[WARNING] Unable to sign the OCI artifacts, the private key is not set"
else
   # cosign uploads a new tag to the registry, so:
   if ! [[ -v CI_REGISTRY_USER ]]; then
      docker login registry.gitlab.com -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD
   fi
fi

if ! [[ -v COSIGN_PASSWORD ]]; then
   echo "[WARNING] Unable to sign the artifacts, the private key password is not available"
fi
