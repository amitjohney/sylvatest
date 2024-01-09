echo "Create image details file"
cat <<EOF>> /tmp/os-image-details.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: os-images-info
  namespace: sylva-system
data:
  values.yaml: |
    osImages:
EOF
yq '.osImages | keys | .[]' /opt/images.yaml | while read OS_IMAGE_KEY; do
  echo "Insert image details "
  export OS_IMAGE_KEY
  echo "      $OS_IMAGE_KEY:" | sed 's/[._]/-/g' >> /tmp/os-image-details.yaml
  # Check if the artifact is a Sylva diskimage-builder artifact
  uri=$(yq '.osImages.[env(OS_IMAGE_KEY)].uri' /opt/images.yaml)
  if [[ "$uri" == *"sylva-elements/diskimage-builder"* ]]; then
    echo "This is a Sylva diskimage-builder image. Updating image details from artifact"
    url=$(echo $uri| sed 's|oci://||')
    # Get artifact annotations and insert them as image details
    manifest=$(oras manifest fetch $url)
    echo $manifest | yq '.annotations |with_entries(select(.key|contains("sylva")))' -P | sed "s|.*/|        |" >> /tmp/os-image-details.yaml
  fi
  echo "Adding user provided details"
  yq '.osImages.[env(OS_IMAGE_KEY)]' /opt/images.yaml | sed 's/^/        /' >> /tmp/os-image-details.yaml
done
# Update configmap
echo "Updating configmap"
kubectl apply -f /tmp/os-image-details.yaml
