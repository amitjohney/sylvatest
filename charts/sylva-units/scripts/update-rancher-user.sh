set -e
echo "-- Fetching KeycloakUser ID..."
i=1
while [ -z $KEYCLOAK_USER_ID ]
do
  sleep 1
  KEYCLOAK_USER_ID=$(kubectl get keycloakuser sylva-user -n keycloak -o jsonpath='{.spec.user.id}')
  i=$(( $i+1 ))
  if [ $i -gt 120 ]
  then
    echo "Timed out waiting for KeycloakUser ID"
    exit 1
  fi
done
echo "-- KeycloakUser ID: $KEYCLOAK_USER_ID"
          
echo "-- Updating User resource with KeycloakUser ID..."

user_name=$(kubectl get users.management.cattle.io '--output=jsonpath={.items[?(@.username=="admin")].metadata.name}')
echo "User '$user_name' has 'username: admin'"
kubectl patch users.management.cattle.io $user_name --type='json' -p "[{'op': 'add', 'path': '/principalIds/-', 'value': 'keycloakoidc_user://$KEYCLOAK_USER_ID'}]"
echo "User resource updated successfully."
