#!/bin/bash
set -e
set -o pipefail

echo "Looking for a kubeconfig for importing clusters"

RANCHER_API=https://${RANCHER_EXTERNAL_URL}/v3
RANCHER_PUBLIC_API=$RANCHER_API-public
USERNAME=cluster-admin
GLOBAL_ROLE=global-cluster-admin

ADMIN_PASSWORD=$(kubectl get secrets -n cattle-system bootstrap-secret -o jsonpath='{.data.bootstrapPassword}' | base64 -d)
if [ $? -ne 0 ]; then
  echo "Could not read the admin password"
  exit 1
fi

CLUSTER_ADMIN_PASSWORD=$(kubectl get secrets -n flux-system cluster-admin-secret -o jsonpath='{.data.password}' | base64 -d)
if [ $? -ne 0 ]; then
  echo "Could not read the password of the cluster-admin user"
  exit 1
fi

# Login token for the admin user
ADMINTOKEN=$(curl -k -s $RANCHER_PUBLIC_API/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"admin","password":"'$ADMIN_PASSWORD'","ttl":10}' | jq -r .token)
if [ $? -ne 0 ]; then
  echo "Could not login to rancher with the admin account"
  exit 1
fi
echo "Obtained a token for the admin user"

# Check if cluster-admin is already created
USER_CREATED=$(curl -k -s -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/users -H 'content-type: application/json' | jq -r '.data[]|select(.username=="'$USERNAME'")|.id' | wc -l)
if [ $USER_CREATED -eq 0 ]; then
  # Create the cluster-admin user
  USERID=$(curl -k -s -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/users -H 'content-type: application/json' --data-binary '{"me":false,"mustChangePassword":false,"type":"user","username":"'$USERNAME'","password":"'$CLUSTER_admin_PASSWORD'","name":"'$USERNAME'"}' | jq -r .id)
  echo "User $USERID created"

  # Assign role
  curl -k -s -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/globalrolebinding -H 'content-type: application/json' --data-binary '{"type":"globalRoleBinding","globalRoleId":"'$GLOBAL_ROLE'","userId":"'$USERID'"}' > /dev/null
  if [ $? -ne 0 ]; then
    echo "Could not assign the $GLOBAL_ROLE role to the cluster-admin user with id $USERID"
    exit 1
  fi
  echo "Role $GLOBAL_ROLE assigned to the cluster-admin user"
else
  # The user is already created, we pick its id
  USERID=$(curl -k -s -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/users -H 'content-type: application/json' | jq -r '.data[]|select(.username=="'$USERNAME'")|.id')
  echo "The user $USERNAME already exists with userid $USERID"
fi
if [ "$USERID" = "" ]; then
  echo "Could not obtain the user id of the $USERNAME user"
  exit 1
fi

# Login token that never expires for the sake of being fully declarative
ADMINTOKEN=$(curl -k -s $RANCHER_PUBLIC_API/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"'$USERNAME'","password":"'$CLUSTER_admin_PASSWORD'","ttl":0}' | jq -r .token)
if [ $? -ne 0 ]; then
  echo "Could not login to rancher with the cluster-admin account"
  exit 1
fi
echo "Obtained a token for the cluster-admin user"

# Get the kubeconfig for the cluster-admin user in the management cluster
KUBECONFIG=$(curl -k -s -X POST -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/clusters/local?action=generateKubeconfig | jq -r '.config')
if [ $? -ne 0 -o "$KUBECONFIG" = "null" ]; then
  echo "Could not obtain a kubeconfig"
  exit 1
fi
echo "Obtained a kubeconfig for the cluster-admin user"

if ! kubectl get secret cluster-admin-kubeconfig -n flux-system > /dev/null 2>&1; then
  kubectl create secret generic cluster-admin-kubeconfig --from-literal=kubeconfig="$KUBECONFIG" --from-literal=USER_NAME=$USERID -n $TARGET_NAMESPACE
  echo "Creating the cluster-admin-kubeconfig secret"
  if [ $? -ne 0 ]; then
    echo "Could not save the kubeconfig in the cluster-admin-kubeconfig secret"
    exit 1
  fi
  echo "Saved the kubeconfig in the cluster-admin-kubeconfig secret"
else
  echo "Updating the cluster-admin-kubeconfig secret"
  kubectl patch secret cluster-admin-kubeconfig -n flux-system --type 'merge' -p '{"data":{"USER_NAME":"'$(echo $USERID | base64)'","kubeconfig":"'$(echo "$KUBECONFIG" | base64 -w0)'"}}' -n $TARGET_NAMESPACE
  echo "Updated the kubeconfig in the cluster-admin-kubeconfig secret"
fi
