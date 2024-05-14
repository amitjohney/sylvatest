#!/bin/bash

Help()
{
   # Display Help
   echo "Generate a Cosign Key pair in a Gitlab project and promote it at the Gitlab group level."
   echo
   echo "Syntax: $(basename "$0") [-c|d|h] PROJECT_ID GROUP_ID"
   echo "options:"
   echo "c     Create Cosign key pair stored in CI variables of PROJECT_ID."
   echo "d     Delete key pair"
   echo "h     Print this Help."
   echo
}

if [ $# -eq 0 ];
then
    echo "This script needs arguments"
    Help
    exit 0
fi

GENERATE_KEY=false
DELETE_KEY=false

while getopts "hcd" option; do
   case $option in
      h) # display Help
         Help
         exit
         ;;
      c) # create key pair
        GENERATE_KEY=true
        ;;
      d) # delete key pair
        DELETE_KEY=true
        ;;
      \?) # Invalid option
         echo "Error: Invalid option"
         exit
         ;;
   esac
done

shift $(($OPTIND -1))

if [ $# -eq 0 ];
then
    echo "[ERROR] PROJET and GROUP IDs are missing"
    Help
    exit 1
fi

PROJECT_ID=$1
GROUP_ID=$2

printf "Project Name: \033[1m%s\033[0m (ID: %s)\n" $(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/${PROJECT_ID}" | jq -r '.name')  $PROJECT_ID 
printf "Group Name: \033[1m%s\033[0m (ID: %s)\n" $(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/${GROUP_ID}" | jq -r '.name') $GROUP_ID 

if ! [[ -v  GITLAB_TOKEN ]]; then
   echo "[ERROR] the environment variable GITLAB_TOKEN is not set"
   exit 1
fi

if $GENERATE_KEY; then
  echo "Generating Project key pair"
  cosign generate-key-pair gitlab://"${PROJECT_ID}"
fi

if $DELETE_KEY; then
   echo "Removing Group key pair"
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables/COSIGN_PRIVATE_KEY" | jq
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables/COSIGN_PASSWORD" | jq
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables/COSIGN_PUBLIC_KEY" | jq

   echo "Removing Project key pair"
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PRIVATE_KEY" | jq 
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PASSWORD" | jq
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PUBLIC_KEY" | jq
else
   echo "Creating Group key pair"

   COSIGN_PRIVATE_KEY=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PRIVATE_KEY" | jq -r '.value')
   COSIGN_PASSWORD=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PASSWORD" | jq -r '.value')
   COSIGN_PUBLIC_KEY=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PUBLIC_KEY" | jq -r '.value')

   printf "Group Variable \033[1m%s\033[0m created\n" $(curl -s -XPOST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables" --form "key=COSIGN_PRIVATE_KEY" --form "value=$COSIGN_PRIVATE_KEY" --form "protected=true" | jq -r '.key')
   printf "Group Variable \033[1m%s\033[0m created\n" $(curl -s -XPOST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables" --form "key=COSIGN_PASSWORD" --form "value=$COSIGN_PASSWORD" --form "protected=true" | jq -r '.key')
   printf "Group Variable \033[1m%s\033[0m created\n" $(curl -s -XPOST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables" --form "key=COSIGN_PUBLIC_KEY" --form "value=$COSIGN_PUBLIC_KEY" | jq -r '.key')
fi
