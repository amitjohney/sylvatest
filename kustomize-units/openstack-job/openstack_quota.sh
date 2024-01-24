#!/bin/bash
echo " *** Openstack available resources validation ***
  verify enough resources are available before deployment:
  - cores
  - ram
  - disk
  - floating-ips
  - instances
  - server-groups
  - security-groups
  - volumes
"
# Verify Credentials against Openstack
RESULT=$(openstack --os-cloud $CLOUD server list 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  if [[ "$RESULT" =~ .*"HTTP 401".* ]]; then
    echo "ERROR >> Openstack authentication failure, check credentials"
  elif [[ "$RESULT" =~ .*"Network unreachable".* ]]; then
    echo "ERROR >> Openstack is unreachable"
  else
    echo "ERROR"
  fi
  echo "$RESULT"
  exit 1
else
  echo "Openstack authentication successful"
fi
# Verify ENV VARS
if [ -z $CONTROL_PLANE_REPLICAS ]; then
  echo "missing CONTROL_PLANE_REPLICAS env var"
  exit 1
fi
if [ -z $TOTAL_MD_REPLICAS ]; then
  # Total number of MD REPLICAS
  echo "missing MD_REPLICAS env var"
  exit 1
fi
if [ -z $TOTAL_MD ]; then
  # Total number of machine deployment groups
  echo "missing MDS env var"
  exit 1
fi
if [ -z $FLAVOR_NAME ]; then
  echo "missing FLAVOR_NAME env var"
  exit 1
fi
if [ -z $CLUSTER_TYPE ]; then
  # Weither the deployment is for management or workload
  echo "missing CLUSTER_TYPE env var"
  exit 1
fi
if [ -z $EXTERNAL_NETWORK_ID ]; then
  # external network ID
  echo "missing EXTERNAL_NETWORK_ID env var"
  exit 1
fi
if [ -z $EXISTING_CP_SERVER_GROUP_ID ]; then
  # Existing CP server group ID (reuse existing one)
  echo "missing EXISTING_CP_SERVER_GROUP_ID env var"
  exit 1
fi
if [ -z $EXISTING_MD_SERVER_GROUPS ]; then
  # Existing MD server groups (reuse existing ones, potentially 1 per MD)
  echo "missing EXISTING_MD_SERVER_GROUPS env var"
  exit 1
fi
printf -- '-%.0s' {1..75}; printf "\n"
printf "|%-73s|\n" "  Env variables  "
printf -- '-%.0s' {1..75}; printf "\n"
printf "%-30s | %40s |\n" "CONTROL_PLANE_REPLICAS" $CONTROL_PLANE_REPLICAS
printf "%-30s | %40s |\n" "TOTAL_MD_REPLICAS" $TOTAL_MD_REPLICAS
printf "%-30s | %40s |\n" "TOTAL_MD" $TOTAL_MD
printf "%-30s | %40s |\n" "CLUSTER_TYPE" $CLUSTER_TYPE
printf "%-30s | %40s |\n" "ROOT_DISK_SIZE" $ROOT_DISK_SIZE
printf "%-30s | %40s |\n" "FLAVOR_NAME" $FLAVOR_NAME
printf "%-30s | %40s |\n" "EXTERNAL_NETWORK_ID" $EXTERNAL_NETWORK_ID
printf "%-30s | %40s |\n" "EXISTING_CP_SERVER_GROUP_ID" $EXISTING_CP_SERVER_GROUP_ID
printf "%-30s | %40s |\n" "EXISTING_MD_SERVER_GROUPS" $EXISTING_MD_SERVER_GROUPS
printf -- '-%.0s' {1..75}; printf "\n\n"
# We retrieve flavor definition from Openstack
openstack --os-cloud $CLOUD flavor show $FLAVOR_NAME -f yaml > /tmp/flavor.yaml
FLAVOR_VCPUS=$(yq '.vcpus' /tmp/flavor.yaml)
FLAVOR_RAM=$(yq '.ram' /tmp/flavor.yaml)
FLAVOR_DISK=$(yq '.disk' /tmp/flavor.yaml)
# OUTPUT FLAVOR DEFINITION
printf -- '-%.0s' {1..40}; printf "\n"
printf "|%-38s|\n" "Flavor chosen $FLAVOR_NAME"
printf -- '-%.0s' {1..40}; printf "\n"
printf "%-25s | %10s |\n" "cores" $FLAVOR_VCPUS
printf "%-25s | %10s |\n" "ram" $FLAVOR_RAM
printf "%-25s | %10s |\n" "disk" $FLAVOR_DISK
printf -- '-%.0s' {1..40}; printf "\n\n"
# 
#  START COMPUTING REQUIRED RESOURCES
#
# Total number of VMs required to be instantiated: control_planes + workers
TOTAL_INSTANCES=$(expr $CONTROL_PLANE_REPLICAS + $TOTAL_MD_REPLICAS )
REQUIRED_VCPUS=$(expr $TOTAL_INSTANCES \* $FLAVOR_VCPUS )
REQUIRED_RAM=$(expr $TOTAL_INSTANCES \* $FLAVOR_RAM )
#
#  SECURITY GROUPS
#
# 5 security groups per deployments
#  - Heat Stack group-common   (management only)
#  - Heat Stack group-ctrl-plane   (management only)
#  - Heat Stack group-worker   (management only)
#  - Cluster API control-plane    (management and workload)
#  - Cluster API worker    (management and workload)
if [ "$CLUSTER_TYPE" = "management" ]; then
  REQUIRED_SECURITY_GROUPS=5
else
  REQUIRED_SECURITY_GROUPS=2
fi
#
# SECURITY GROUP RULES
#
# 5 security groups per deployments
#  - Heat Stack group-common : 6 rules
#  - Heat Stack group-ctrl-plane: 2 rules
#  - Heat Stack group-worker : 2 rules
#  - Cluster API control-plane : 5 rules
#  - Cluster API worker : 6 rules
HEAT_STACK_MANAGED_COMMON_SECURITY_GROUP_FOR_CP_AND_WORKERS=6
HEAT_STACK_MANAGED_COMMON_SECURITY_GROUP_FOR_CP=2
HEAT_STACK_MANAGED_COMMON_SECURITY_GROUP_FOR_WORKERS=2
CAPI_SECURITY_GROUP_FOR_WORKERS=6
CAPI_SECURITY_GROUP_FOR_CP=5
if [ "$CLUSTER_TYPE" = "management" ]; then
  REQUIRED_SECURITY_GROUPS_RULES=$(expr $HEAT_STACK_MANAGED_COMMON_SECURITY_GROUP_FOR_CP_AND_WORKERS + $HEAT_STACK_MANAGED_COMMON_SECURITY_GROUP_FOR_CP + $HEAT_STACK_MANAGED_COMMON_SECURITY_GROUP_FOR_WORKERS + $CAPI_SECURITY_GROUP_FOR_WORKERS + $CAPI_SECURITY_GROUP_FOR_CP )
else
  REQUIRED_SECURITY_GROUPS_RULES=$(expr $CAPI_SECURITY_GROUP_FOR_WORKERS + $CAPI_SECURITY_GROUP_FOR_CP )
fi
#
# DISK or VOLUMES SIZE (in GB)
#
KEYCLOAK_VOL_SIZE=8
VAULT_VOL_SIZE=1
HARBOR_VOL_REDIS_SIZE=1
HARBOR_VOL_DB_SIZE=1
HARBOR_VOL_JOB_SIZE=1
HARBOR_VOL_REGISTRY_SIZE=5
if [ "$CLUSTER_TYPE" = "management" ]; then
  TOTAL_KEYCLOAK_SIZE=$(expr \( $CONTROL_PLANE_REPLICAS + 1 \) \* $KEYCLOAK_VOL_SIZE)
  TOTAL_VAULT_SIZE=$(expr $CONTROL_PLANE_REPLICAS \* $VAULT_VOL_SIZE)
  TOTAL_HARBOR_SIZE=$(expr $HARBOR_VOL_REDIS_SIZE + $HARBOR_VOL_DB_SIZE + $HARBOR_VOL_JOB_SIZE + $HARBOR_VOL_REGISTRY_SIZE )
  KEYCLOAK_VOLS=$(expr $CONTROL_PLANE_REPLICAS + 1)
  VAULT_VOLS=$CONTROL_PLANE_REPLICAS
  HARBOR_VOLS=$(expr $CONTROL_PLANE_REPLICAS + 1)
else
  TOTAL_KEYCLOAK_SIZE=0
  TOTAL_VAULT_SIZE=0
  TOTAL_HARBOR_SIZE=0
  KEYCLOAK_VOLS=0
  VAULT_VOLS=0
  HARBOR_VOLS=0
fi
if [ -z $ROOT_DISK_SIZE ]; then
  REQUIRED_DISK=0
  ROOT_VOLS=0
  REQUIRED_VOLUMES=0
else
  REQUIRED_DISK=$(expr $TOTAL_INSTANCES \* $ROOT_DISK_SIZE + $TOTAL_KEYCLOAK_SIZE + $TOTAL_VAULT_SIZE + $TOTAL_HARBOR_SIZE)
  ROOT_VOLS=$(expr $CONTROL_PLANE_REPLICAS + $TOTAL_MD_REPLICAS)
  REQUIRED_VOLUMES=$(expr $ROOT_VOLS + $KEYCLOAK_VOLS + $VAULT_VOLS + $HARBOR_VOLS)
fi

#
#  FLOATING-IPS
#
if [ "$CLUSTER_TYPE" = "management" ] && [ "$EXTERNAL_NETWORK_ID" != "none" ]; then
  REQUIRED_FIP=1
else
  REQUIRED_FIP=0
fi
#
# SERVER GROUPS
#
REQUIRED_SERVER_GROUPS=0
if [ "$EXISTING_CP_SERVER_GROUP_ID" = "none" ]; then
  # No server-group to reuse for Control Plane
  REQUIRED_SERVER_GROUPS=$(expr $REQUIRED_SERVER_GROUPS + 1)
fi
# we add 1 server-group per MD minus the number of reuse server groups already existing
REQUIRED_SERVER_GROUPS=$(expr $REQUIRED_SERVER_GROUPS + $TOTAL_MD - $EXISTING_MD_SERVER_GROUPS)
#
# OUTPUT REQUIRED RESOURCES
# 
printf -- '-%.0s' {1..40}; printf "\n"
printf '|%-38s|\n' "Required resources"
printf -- '-%.0s' {1..40}; printf "\n"
printf "%-25s | %10s |\n" "cores" $REQUIRED_VCPUS
printf "%-25s | %10s |\n" "ram" $REQUIRED_RAM
printf "%-25s | %10s |\n" "disk" $REQUIRED_DISK
printf "%-25s | %10s | %s cp %s md\n" "instances" $TOTAL_INSTANCES $CONTROL_PLANE_REPLICAS $TOTAL_MD_REPLICAS
printf "%-25s | %10s |\n" "floating-ips" $REQUIRED_FIP
printf "%-25s | %10s |\n" "server-groups" $REQUIRED_SERVER_GROUPS
printf "%-25s | %10s |\n" "security-groups" $REQUIRED_SECURITY_GROUPS
printf "%-25s | %10s |\n" "security-groups-rules" $REQUIRED_SECURITY_GROUPS_RULES
printf "%-25s | %10s |\n" "volumes" $REQUIRED_VOLUMES
printf -- '-%.0s' {1..40}; printf "\n\n"
#
# RETRIEVE QUOTA INFORMATION
#
openstack --os-cloud $CLOUD quota show --all --usage -f yaml > /tmp/quotas.yaml
QUOTA_VCPUS_LIMIT=$(yq '. | map(select(.Resource == "cores")).0.Limit' /tmp/quotas.yaml)
QUOTA_VCPUS_USED=$(yq '. | map(select(.Resource == "cores")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_RAM_LIMIT=$(yq '. | map(select(.Resource == "ram")).0.Limit' /tmp/quotas.yaml)
QUOTA_RAM_USED=$(yq '. | map(select(.Resource == "ram")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_DISK_LIMIT=$(yq '. | map(select(.Resource == "gigabytes")).0.Limit' /tmp/quotas.yaml)
QUOTA_DISK_USED=$(yq '. | map(select(.Resource == "gigabytes")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_INSTANCES_LIMIT=$(yq '. | map(select(.Resource == "instances")).0.Limit' /tmp/quotas.yaml)
QUOTA_INSTANCES_USED=$(yq '. | map(select(.Resource == "instances")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_FIP_LIMIT=$(yq '. | map(select(.Resource == "floating-ips")).0.Limit' /tmp/quotas.yaml)
QUOTA_FIP_USED=$(yq '. | map(select(.Resource == "floating-ips")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_SERVER_GROUPS_LIMIT=$(yq '. | map(select(.Resource == "server-groups")).0.Limit' /tmp/quotas.yaml)
QUOTA_SERVER_GROUPS_USED=$(yq '. | map(select(.Resource == "server-groups")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_SECURITY_GROUPS_LIMIT=$(yq '. | map(select(.Resource == "secgroups")).0.Limit' /tmp/quotas.yaml)
QUOTA_SECURITY_GROUPS_USED=$(yq '. | map(select(.Resource == "secgroups")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_SECURITY_GROUPS_RULES_LIMIT=$(yq '. | map(select(.Resource == "secgroup-rules")).0.Limit' /tmp/quotas.yaml)
QUOTA_SECURITY_GROUPS_RULES_USED=$(yq '. | map(select(.Resource == "secgroup-rules")).0.["In Use"]' /tmp/quotas.yaml)
QUOTA_VOLUMES_LIMIT=$(yq '. | map(select(.Resource == "volumes")).0.Limit' /tmp/quotas.yaml)
QUOTA_VOLUMES_USED=$(yq '. | map(select(.Resource == "volumes")).0.["In Use"]' /tmp/quotas.yaml)
#check CPU resources
if [ $QUOTA_VCPUS_LIMIT -eq -1 ]; then
  QUOTA_VCPUS_STATUS="pass"
else
  QUOTA_VCPUS_AVAILABLE=$(expr $QUOTA_VCPUS_LIMIT - $QUOTA_VCPUS_USED)
  if [ $QUOTA_VCPUS_AVAILABLE -lt $REQUIRED_VCPUS ]; then
    QUOTA_VCPUS_STATUS="fail"
  else
    QUOTA_VCPUS_STATUS="pass"
  fi
fi
# Check RAM resources
if [ $QUOTA_RAM_LIMIT -eq -1 ]; then
  QUOTA_RAM_STATUS="pass"
else
  QUOTA_RAM_AVAILABLE=$(expr $QUOTA_RAM_LIMIT - $QUOTA_RAM_USED)
  if [ $QUOTA_RAM_AVAILABLE -lt $REQUIRED_RAM ]; then
    QUOTA_RAM_STATUS="fail"
  else
    QUOTA_RAM_STATUS="pass"
  fi
fi
# Check DISK resources
if [ $QUOTA_DISK_LIMIT -eq -1 ]; then
  QUOTA_DISK_STATUS="pass"
else
  QUOTA_DISK_AVAILABLE=$(expr $QUOTA_DISK_LIMIT - $QUOTA_DISK_USED)
  if [ $QUOTA_DISK_AVAILABLE -lt $REQUIRED_DISK ]; then
    QUOTA_DISK_STATUS="fail"
  else
    QUOTA_DISK_STATUS="pass"
  fi
fi
# Check INSTANCES resources
if [ $QUOTA_INSTANCES_LIMIT -eq -1 ]; then
  QUOTA_INSTANCES_STATUS="pass"
else
  QUOTA_INSTANCES_AVAILABLE=$(expr $QUOTA_INSTANCES_LIMIT - $QUOTA_INSTANCES_USED)
  if [ $QUOTA_INSTANCES_AVAILABLE -lt $TOTAL_INSTANCES ]; then
    QUOTA_INSTANCES_STATUS="fail"
  else
    QUOTA_INSTANCES_STATUS="pass"
  fi
fi
# Check FIP resources
if [ $QUOTA_FIP_LIMIT -eq -1 ]; then
  QUOTA_FIP_STATUS="pass"
else
  QUOTA_FIP_AVAILABLE=$(expr $QUOTA_FIP_LIMIT - $QUOTA_FIP_USED)
  if [ $QUOTA_FIP_AVAILABLE -lt $REQUIRED_FIP ]; then
    QUOTA_FIP_STATUS="fail"
  else
    QUOTA_FIP_STATUS="pass"
  fi
fi
# Check SERVER_GROUPS resources
if [ $QUOTA_SERVER_GROUPS_LIMIT -eq -1 ]; then
  QUOTA_SERVER_GROUPS_STATUS="pass"
else
  QUOTA_SERVER_GROUPS_AVAILABLE=$(expr $QUOTA_SERVER_GROUPS_LIMIT - $QUOTA_SERVER_GROUPS_USED)
  if [ $QUOTA_SERVER_GROUPS_AVAILABLE -lt $REQUIRED_SERVER_GROUPS ]; then
    QUOTA_SERVER_GROUPS_STATUS="fail"
  else
    QUOTA_SERVER_GROUPS_STATUS="pass"
  fi
fi
# Check SECURITY_GROUPS resources
if [ $QUOTA_SECURITY_GROUPS_LIMIT -eq -1 ]; then
  QUOTA_SECURITY_GROUPS_STATUS="pass"
else
  QUOTA_SECURITY_GROUPS_AVAILABLE=$(expr $QUOTA_SECURITY_GROUPS_LIMIT - $QUOTA_SECURITY_GROUPS_USED)
  if [ $QUOTA_SECURITY_GROUPS_AVAILABLE -lt $REQUIRED_SECURITY_GROUPS ]; then
    QUOTA_SECURITY_GROUPS_STATUS="fail"
  else
    QUOTA_SECURITY_GROUPS_STATUS="pass"
  fi
fi
# Check SECURITY_GROUPS_RULES resources
if [ $QUOTA_SECURITY_GROUPS_RULES_LIMIT -eq -1 ]; then
  QUOTA_SECURITY_GROUPS_RULES_STATUS="pass"
else
  QUOTA_SECURITY_GROUPS_RULES_AVAILABLE=$(expr $QUOTA_SECURITY_GROUPS_RULES_LIMIT - $QUOTA_SECURITY_GROUPS_RULES_USED)
  if [ $QUOTA_SECURITY_GROUPS_RULES_AVAILABLE -lt $REQUIRED_SECURITY_GROUPS_RULES ]; then
    QUOTA_SECURITY_GROUPS_RULES_STATUS="fail"
  else
    QUOTA_SECURITY_GROUPS_RULES_STATUS="pass"
  fi
fi
# Check VOLUMES resources
if [ $QUOTA_VOLUMES_LIMIT -eq -1 ]; then
  QUOTA_VOLUMES_STATUS="pass"
else
  QUOTA_VOLUMES_AVAILABLE=$(expr $QUOTA_VOLUMES_LIMIT - $QUOTA_VOLUMES_USED)
  if [ $QUOTA_VOLUMES_AVAILABLE -lt $REQUIRED_VOLUMES ]; then
    QUOTA_VOLUMES_STATUS="fail"
  else
    QUOTA_VOLUMES_STATUS="pass"
  fi
fi

printf -- '-%.0s' {1..80}; printf "\n"
printf "%-25s | %10s | %10s | %10s | %10s\n" "quota" "limit" "used" "required" "test"
printf -- '-%.0s' {1..80}; printf "\n"
printf "%-25s | %10s | %10s | %10s | %10s\n" "cores" $QUOTA_VCPUS_LIMIT  $QUOTA_VCPUS_USED  $REQUIRED_VCPUS $QUOTA_VCPUS_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "ram" $QUOTA_RAM_LIMIT  $QUOTA_RAM_USED  $REQUIRED_RAM $QUOTA_RAM_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "disk" $QUOTA_DISK_LIMIT  $QUOTA_DISK_USED  $REQUIRED_DISK $QUOTA_DISK_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "instances" $QUOTA_INSTANCES_LIMIT  $QUOTA_INSTANCES_USED  $TOTAL_INSTANCES $QUOTA_INSTANCES_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "floating-ips" $QUOTA_FIP_LIMIT  $QUOTA_FIP_USED  $REQUIRED_FIP $QUOTA_FIP_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "server-group" $QUOTA_SERVER_GROUPS_LIMIT  $QUOTA_SERVER_GROUPS_USED  $REQUIRED_SERVER_GROUPS $QUOTA_SERVER_GROUPS_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "security-groups" $QUOTA_SECURITY_GROUPS_LIMIT  $QUOTA_SECURITY_GROUPS_USED  $REQUIRED_SECURITY_GROUPS $QUOTA_SECURITY_GROUPS_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "security-group rules" $QUOTA_SECURITY_GROUPS_RULES_LIMIT  $QUOTA_SECURITY_GROUPS_RULES_USED  $REQUIRED_SECURITY_GROUPS_RULES $QUOTA_SECURITY_GROUPS_RULES_STATUS
printf "%-25s | %10s | %10s | %10s | %10s\n" "volumes" $QUOTA_VOLUMES_LIMIT  $QUOTA_VOLUMES_USED  $REQUIRED_VOLUMES $QUOTA_VOLUMES_STATUS
printf -- '-%.0s' {1..80}; printf "\n"
if [ "$QUOTA_VCPUS_STATUS" != "pass" ] || [ "$QUOTA_RAM_STATUS" != "pass" ] || [ "$QUOTA_DISK_STATUS" != "pass" ] || [ "$QUOTA_INSTANCES_STATUS" != "pass" ] || [ "$QUOTA_FIP_STATUS" != "pass" ] || [ "$QUOTA_SERVER_GROUPS_STATUS" != "pass" ] || [ "$QUOTA_SECURITY_GROUPS_STATUS" != "pass" ] || [ "$QUOTA_SECURITY_GROUPS_RULES_STATUS" != "pass" ] || [ "$QUOTA_VOLUMES_STATUS" != "pass" ]; then
  echo "==X Deployment can't continue: not enough resources"
  exit 1
else
  echo "==> Deployment can continue on OpenStack"
fi
