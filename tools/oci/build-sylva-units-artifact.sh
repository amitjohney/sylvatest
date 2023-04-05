#!/bin/bash
#
# This script will push to registry.gitlab.com an OCI registry artifact
# containing the 'sylva-units' Helm chart.
#
# The artifact is pushed as:
#  oci://registry.gitlab.com/sylva-projects/sylva-core/sylva-units:<tag>
#
# The pushed chart will contain a values override file, 'use-oci-registry.values.yaml'
# that can be used to override all external sources definitions (from source_templates and helm_repo_url)
# to make them points to OCI Registry artifacts.
#
#
# ### How to use ###
#
# The script accepts an optional parameter, which will be used as <tag> above.
# By default the current commit id will be used as <tag>.
#
# If run manually, the tool can be used after having preliminarily done
# a 'helm registry login registry.gitlab.com' with suitable credentials.

# Requirements:
# - flux (used to push the artifact)
# - yq

set -eu
set -o pipefail

BASE_DIR="$(realpath $(dirname $0)/../..)"

# the OCI registry to use is:
# - $OCI_REGISTRY if defined
# - the gitlab CI registry, $CI_REGISTRY (if applicable)
# - default value is oci://registry.gitlab.com/sylva-projects/sylva-core
OCI_REGISTRY=${OCI_REGISTRY:-oci://registry.gitlab.com/sylva-projects/sylva-core}

helm_chart_version="${1:-0.0.0-git+$(git rev-parse --short HEAD)}"

artifact_dir=$(mktemp -d -t sylva-units-XXXXXX)
#trap "rm -rf $artifact_dir" EXIT INT

echo "(working in $artifact_dir)"
echo

cd $artifact_dir

cp -r $BASE_DIR/charts/sylva-units $artifact_dir
cd $artifact_dir/sylva-units

############################### package charts/sylva-units #########################################################

echo "Preparing chart..."

## put git tag in sylva-units chart Chart.yaml
yq -i ".version = \"$helm_chart_version\"" Chart.yaml

############################### sylva-units overrides to consume Helm charts from OCI artifacts ####################

echo "Preparing use-oci-artifacts.values.yaml values override file..."

# Here we build a values override file for sylva-units to allow to conveniently
# use sylva-units from OCI registry artifacts.

# The URLs used here match the location at which the script tools/oci/push-helm-charts-artifact.sh
# creates them



# ********* Helm-based units relying on 'helm_repo_url' *********

# for those units, we just need to override the URL with the OCI registry URL
#
# Example:
#
# Unit definition:
#
#   cert-manager:
#     enabled: yes
#     helm_repo_url: https://charts.jetstack.io
#     helmrelease_spec:
#     chart:
#       spec:
#         chart: cert-manager
#         version: v1.11.0
#
# Produced override to use the OCI registry:
#
#    cert-manager:
#      helm_repo_url: '{{ sylva_core_oci_registry }}'
#
# Note that 'sylva_core_oci_registry' defaults to 'oci://registry.gitlab.com/sylva-projects/sylva-core'
# and can be overriden at deployment time

# shellcheck disable=SC2016
yq eval-all -i '
    select(fileIndex==1).units as $reference_units |
    ( select(fileIndex==0).units =
        (([ $reference_units | ... comments="" | to_entries | .[] | select(.value | has("helm_repo_url")) ]
          | map({
              "key": .key,
              "value": {
                "helm_repo_url": "{{ .Values.sylva_core_oci_registry }}"
              }
            })
        ) | from_entries)
    )
    | select(fileIndex==0)' \
    use-oci-artifacts.values.yaml values.yaml

# ********* Helm-based units relying on 'repo' *********

# For such units, we:
# * replace 'repo: xxx' by 'helm_repo_url'
# * inject the version found in source_templates.xxx.spec.ref.tag into the unit helmrelease_spec.chart.spec.version
#
# Example:
#
# For unit 'local-path-provisioner'...
#
# source_templates:
#   local-path-provisioner:
#     kind: GitRepository
#     spec:
#       url: https://github.com/rancher/local-path-provisioner.git
#       ref:
#         tag: v0.0.23
# units:
#   local-path-provisioner:
#     enabled: yes
#     repo: local-path-provisioner
#     helmrelease_spec:
#       chart:
#         spec:
#           chart: deploy/chart/local-path-provisioner
#
# ...We produce this override:
#
#   local-path-provisioner:
#     repo: null
#     helm_repo_url: '{{ sylva_core_oci_registry }}'
#     helmrelease_spec:
#       chart:
#         spec:
#           chart: local-path-provisioner
#           version: v0.0.23

# shellcheck disable=SC2016
yq eval-all -i '
      select(fileIndex==1).source_templates as $source_templates
    | select(fileIndex==1).units as $reference_units
    | select(fileIndex==0).units as $units
    |
    ( select(fileIndex==0).units =
        ([ $reference_units | ... comments="" | to_entries | .[] | select((.value | has("repo")) and
                                                                          (.value | has("helmrelease_spec")))]
            | map({
                   "key": .key,
                   "value": {
                     "repo": null,
                     "helm_repo_url": "{{ .Values.sylva_core_oci_registry }}",
                     "helmrelease_spec": {
                       "chart": {
                         "spec": {
                           "chart": .value.repo,
                           "version": $source_templates[.value.repo].spec.ref.tag
                         }
                       }
                     }
                   }
                 })
            | from_entries
        ) * $units
    )
    | select(fileIndex==0)' \
    use-oci-artifacts.values.yaml values.yaml

# For 'sylva-units' unit in bootstrap.values.yaml we need specific processing
# because the chart name is 'sylva-units' (not equal to 'repo' which is 'sylva-core')
# and because the tag to use is $artifact_tag (not derived from source_template."sylva-core".spec.ref.tag)

export helm_chart_version

yq eval -i '
    .units."sylva-units" =
        {
          "enabled": false,
          "repo": null,
          "helm_repo_url": "{{ .Values.sylva_core_oci_registry }}",
          "helmrelease_spec": {
            "chart": {
              "spec": {
                "chart": "sylva-units",
                "version": strenv(helm_chart_version)
              }
            }
          }
        }
    ' \
    use-oci-artifacts.values.yaml

############################### wrap up Helm packaging

echo "Wrap up Helm chart package..."

# remove test values
rm -rf test-values

helm dependency update .

helm package --version $helm_chart_version .

############################### pushing the artifact to registry ###################################################

echo
echo "Pushing sylva-units artifact to OCI registry..."

if [[ -n ${CI_REGISTRY:-} ]]; then
    echo "$CI_REGISTRY_PASSWORD" | helm registry login -u $CI_REGISTRY_USER $CI_REGISTRY --password-stdin
fi

helm push sylva-units-$helm_chart_version.tgz $OCI_REGISTRY

## TODO/future: see if we can use plain 'flux' to push the Helm chart

# if we run in a gitlab CI job, then we use the credentials provided by gitlab job environment
# if [[ -n ${CI_REGISTRY_USER:-} ]]; then
#     creds="--creds $CI_REGISTRY_USER:$CI_REGISTRY_PASSWORD"
# fi

# flux push artifact $OCI_REGISTRY/sylva-units:$helm_chart_version \
# 	--path=. \
# 	--source=$artifact_source \
# 	--revision=$artifact_revision \
#     ${creds:-}
