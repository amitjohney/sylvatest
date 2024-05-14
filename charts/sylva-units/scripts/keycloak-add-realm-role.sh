#!/bin/bash

set -e
set -o pipefail

# workaround for https://gitlab.com/sylva-projects/sylva-core/-/issues/144
echo "-- Wait for Keycloak realm resource to be ready and created by keycloak operators"
attempts=0
max_attempts=5
until kubectl get -n keycloak keycloakrealmimport.k8s.keycloak.org sylva -o json | jq -e '.status.conditions[]|select(.type=="Done")|.status'; do
    sleep 3
    ((attempts++)) && ((attempts==max_attempts)) && echo "timed out waiting for sylva keycloakrealmimport to become ready" && exit -1
done

KEYCLOAK_BASE_URL="https://keycloak.sylva"
KEYCLOAK_INITIAL_USERNAME="admin"
KEYCLOAK_REALM="sylva"
KEYCLOAK_ROLE="grafanaadmin"
KEYCLOAK_USERNAME="sylva-admin"

echo "-- Retrieve Keycloak admin initial password"
KEYCLOAK_INITIAL_PASSWORD=$(kubectl -n keycloak get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 -d)

echo $KEYCLOAK_INITIAL_PASSWORD

echo "-- Retrieve Keycloak access token"
ACCESS_TOKEN=$(curl -k -s -X POST \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "username=${KEYCLOAK_INITIAL_USERNAME}" \
-d "password=${KEYCLOAK_INITIAL_PASSWORD}" \
-d "grant_type=password" \
-d "client_id=admin-cli" \
${KEYCLOAK_BASE_URL}/realms/master/protocol/openid-connect/token \
| jq -r '.access_token')
if [ -z "${ACCESS_TOKEN-unset}" ]; then
    echo "ACCESS_TOKEN is set to the empty string, will try again"
    exit 1
fi

echo "-- Check that sylva realm was already created by keycloak-operator"
NON_MASTER_REALM=$(curl -k -s -X GET \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${ACCESS_TOKEN}" \
${KEYCLOAK_BASE_URL}/admin/realms \
| jq -r '.[] | select( (.realm | test("^master$")|not) ).realm')
if [ "$NON_MASTER_REALM" != "sylva" ]; then
    echo "The sylva realm is not yet ready, will try again"
    exit 1
fi

echo "-- Create custom realm role"
curl -k -s -X POST \
-H "Content-Type: application/json" \
-H "Authorization: Bearer ${ACCESS_TOKEN}" \
-d '{
        "name": "grafanaadmin",
        "description": "Admin role for Grafana",
        "composite": false,
        "clientRole": false,
        "containerId": "sylva"
}' \
${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/roles

# Debugging output
echo -e "\n-- Debug: Retrieve User Info --"
echo "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/users?username=${KEYCLOAK_USERNAME}"

# Find user ID
USER_ID=$(curl -k -s -X GET "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/users?username=${KEYCLOAK_USERNAME}" \
        -H "Authorization: Bearer ${ACCESS_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.[0].id')

# Debugging output
echo "User ID: $USER_ID"

if [ -z "$USER_ID" ]; then
    echo "User ID not found for username: $KEYCLOAK_USERNAME"
    exit 1
fi

echo "-- Find role ID"
# Find role ID
ROLE_ID=$(curl -k -s -X GET "${KEYCLOAK_BASE_URL}/admin/realms/${KEYCLOAK_REALM}/roles/${KEYCLOAK_ROLE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" | jq -r '.id')

# Debugging output
echo "Role ID: $ROLE_ID"

if [ -z "$ROLE_ID" ]; then
    echo "Role ID not found for role: $KEYCLOAK_ROLE"
    exit 1
fi

echo "-- Assign role to user"
# Assign role to user
curl -k -s -X POST "$KEYCLOAK_BASE_URL/admin/realms/${KEYCLOAK_REALM}/users/$USER_ID/role-mappings/realm" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '[
    {
      "id": "'"$ROLE_ID"'",
      "name": "'"$KEYCLOAK_ROLE"'"
    }
  ]'

echo "Role $KEYCLOAK_ROLE assigned to user $KEYCLOAK_USERNAME"

echo "-- All done"
