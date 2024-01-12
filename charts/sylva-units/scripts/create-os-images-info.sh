#!/bin/bash

set -e
set -o pipefail

echo "Initiate ConfigMap manifest file"

configmap_file=/tmp/os-image-details.yaml

cat <<EOF >> $configmap_file
apiVersion: v1
kind: ConfigMap
metadata:
  name: os-images-info
  namespace: sylva-system
data:
  values.yaml: |
    osImages:
EOF

echo "Looping over OS images..."

yq '.osImages | keys | .[]' /opt/images.yaml | while read os_image_key; do
  echo "-- processing image $os_image_key"
  export os_image_key
  echo "      $os_image_key:" | sed 's/[._]/-/g' >> $configmap_file
  # Check if the artifact is a Sylva diskimage-builder artifact
  uri=$(yq '.osImages.[env(os_image_key)].uri' /opt/images.yaml)
  if [[ "$uri" == *"sylva-elements/diskimage-builder"* ]]; then
    echo "This is a Sylva diskimage-builder image. Updating image details from artifact at $uri"
    url=$(echo $uri| sed 's|oci://||')
    # Get artifact annotations and insert them as image details
    manifest=$(oras manifest fetch $url)
    echo $manifest | yq '.annotations |with_entries(select(.key|contains("sylva")))' -P | sed "s|.*/|        |" >> $configmap_file
  fi
  echo "Adding user provided details"
  yq '.osImages.[env(os_image_key)]' /opt/images.yaml | sed 's/^/        /' >> $configmap_file
  echo ---
done

# Update configmap
echo "Updating os-images-info configmap"
unset https_proxy  # for https://gitlab.com/sylva-projects/sylva-core/-/issues/859
kubectl apply -f $configmap_file
