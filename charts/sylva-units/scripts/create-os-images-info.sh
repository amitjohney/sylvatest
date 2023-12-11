echo "Create image details file"
echo -e "data:\n  values.yaml: |\n    osImages:" > /tmp/os-image-details.yaml
yq '.osImages | keys | .[]' /opt/images.yaml | while read line; do
  echo "Insert image details "
  export LINE=$line
  echo "      $LINE:" >> /tmp/os-image-details.yaml
  # Check if the artifact is a Sylva diskimage-builder artifact
  uri=$(yq '.osImages.[env(LINE)].uri' /opt/images.yaml)
  if [[ "$uri" == *"sylva-elements/diskimage-builder"* ]]; then
    echo "This is a Sylva diskimage-builder image. Updating image details from artifact"
    echo "        uri: $uri" >> /tmp/os-image-details.yaml
    url=$(echo $uri| sed 's|oci://||')
    # Get artifact annotations and insert them as image details
    manifest=$(oras manifest fetch $url)
    echo $manifest | yq '.annotations |with_entries(select(.key|contains("sylva")))' -P | sed "s|.*/|        |" >> /tmp/os-image-details.yaml
  else
    echo "Updating image details for custom image"
    yq '.osImages.[env(LINE)]' /opt/images.yaml | sed 's/^/        /' >> /tmp/os-image-details.yaml
  fi
done
# Verify os-images-info configmap or create an empty one
if ! kubectl -n sylva-system get cm os-images-info &>/dev/null; then
  # Initialize new configmap
  kubectl -n sylva-system create configmap os-images-info
fi
# Update configmap
echo "Updating configmap"
kubectl -n sylva-system patch configmap os-images-info --patch-file /tmp/os-image-details.yaml
