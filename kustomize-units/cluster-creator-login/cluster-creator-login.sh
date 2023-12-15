#!/bin/bash
set -e
set -o pipefail

echo "Looking for a kubeconfig for importing clusters"

RANCHER_API=https://${RANCHER_EXTERNAL_URL}/v3
RANCHER_PUBLIC_API=$RANCHER_API-public
USERNAME=cluster-creator
GLOBAL_ROLE=global-cluster-creator

ADMIN_PASSWORD=$(kubectl get secrets -n cattle-system bootstrap-secret -o jsonpath='{.data.bootstrapPassword}' | base64 -d)
if [ $? -ne 0 ]; then
  echo "Could not read the admin password"
  exit 1
fi

CLUSTER_CREATOR_PASSWORD=$(kubectl get secrets -n flux-system cluster-creator-secret -o jsonpath='{.data.password}' | base64 -d)
if [ $? -ne 0 ]; then
  echo "Could not read the password of the cluster-creator user"
  exit 1
fi

# Login token for the admin user
REQ_TOKEN=$(curl -k -s $RANCHER_PUBLIC_API/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"admin","password":"'$ADMIN_PASSWORD'","ttl":10}')
ADMINTOKEN=$(echo $REQ_TOKEN | jq -r .token)
if [ $ADMINTOKEN == "null" ]; then
  echo "Problem when authenticating as the admin user"
  echo $REQ_TOKEN
  exit 1
fi

echo "Obtained a token for the admin user"

# Check if cluster-creator is already created
USERS=$(curl -k -s -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/users -H 'content-type: application/json')
if [ $? -ne 0 ]; then
  echo "Couldn't list the users"
  echo $USERS
fi

USER_CREATED=$(echo $USERS | jq -r '.data[]|select(.username=="'$USERNAME'")|.id' | wc -l)
if [ $USER_CREATED -eq 0 ]; then
  echo "Creating the cluster-creator user"
  # Create the cluster-creator user
  REQ_USERID=$(curl -k -s -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/users -H 'content-type: application/json' --data-binary '{"me":false,"mustChangePassword":false,"type":"user","username":"'$USERNAME'","password":"'$CLUSTER_CREATOR_PASSWORD'","name":"'$USERNAME'"}')
  USERID=$(echo $REQ_USERID | jq -r .id)
  if [ $USERID == "null" ]; then
    echo "Problem when creating the cluster-creator user"
    echo $REQ_USERID
    exit 1
  fi
  echo "User $USERID created"

  # Assign role
  REQ_ROLEBINDING=$(curl -k -s -H "Authorization: Bearer $ADMINTOKEN" $RANCHER_API/globalrolebinding -H 'content-type: application/json' --data-binary '{"type":"globalRoleBinding","globalRoleId":"'$GLOBAL_ROLE'","userId":"'$USERID'"}')
  if [ $? -ne 0 ] || [ $(echo $REQ_ROLEBINDING | jq -r ".baseType") == "error" ]; then
    echo "Could not assign the $GLOBAL_ROLE role to the cluster-creator user with id $USERID"
    exit 1
  fi
  echo "Role $GLOBAL_ROLE assigned to the cluster-creator user"
else
  # The user is already created, we pick its id
  USERID=$(echo $USERS | jq -r '.data[]|select(.username=="'$USERNAME'")|.id')
  echo "The user $USERNAME already exists with userid $USERID"
fi
if [ "$USERID" = "" ]; then
  echo "Could not obtain the user id of the $USERNAME user"
  echo "Existing users: $USERS"
  exit 1
fi

# Login token that never expires for the sake of being fully declarative
REQ_CREATORTOKEN=$(curl -k -s $RANCHER_PUBLIC_API/localProviders/local?action=login -H 'content-type: application/json' --data-binary '{"username":"'$USERNAME'","password":"'$CLUSTER_CREATOR_PASSWORD'","ttl":0}')
CREATORTOKEN=$(echo $REQ_CREATORTOKEN | jq -r .token)
if [ $CREATORTOKEN == "null" ]; then
  echo "Could not login to rancher with the cluster-creator account"
  exit 1
fi
echo "Obtained a token for the cluster-creator user" $CREATORTOKEN

# Get the kubeconfig for the cluster-creator user in the management cluster
REQ_KUBECONFIG=$(curl -k -s -X POST -H "Authorization: Bearer $CREATORTOKEN" $RANCHER_API/clusters/local?action=generateKubeconfig)
KUBECONFIG=$(echo $REQ_KUBECONFIG | jq -r '.config')
if [ "$KUBECONFIG" = "null" ]; then
  echo "Could not obtain a kubeconfig"
  echo $REQ_KUBECONFIG
  exit 1
fi
echo "Obtained a kubeconfig for the cluster-creator user"

if ! kubectl get secret cluster-creator-kubeconfig -n flux-system > /dev/null 2>&1; then
  kubectl create secret generic cluster-creator-kubeconfig --from-literal=kubeconfig="$KUBECONFIG" --from-literal=USER_NAME=$USERID -n $TARGET_NAMESPACE
  echo "Creating the cluster-creator-kubeconfig secret"
  if [ $? -ne 0 ]; then
    echo "Could not save the kubeconfig in the cluster-creator-kubeconfig secret"
    exit 1
  fi
  echo "Saved the kubeconfig in the cluster-creator-kubeconfig secret"
else
  echo "Updating the cluster-creator-kubeconfig secret"
  kubectl patch secret cluster-creator-kubeconfig -n flux-system --type 'merge' -p '{"data":{"USER_NAME":"'$(echo $USERID | base64)'","kubeconfig":"'$(echo "$KUBECONFIG" | base64 -w0)'"}}' -n $TARGET_NAMESPACE
  echo "Updated the kubeconfig in the cluster-creator-kubeconfig secret"
fi
