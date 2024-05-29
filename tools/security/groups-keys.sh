#!/bin/bash

Help()
{
   # Display Help
   echo "Manages Cosign Key pair at the Gitlab Group level"
   echo "  - Moves an existing Cosign Key pair from a Gitlab project to a Gitlab group."
   echo "  - Creates a Cosign Key pair in a Gitlab project then moves it to a Gitlab group."
   echo "  - Deletes a Cosign Key pair from a Gitlab group"
   echo
   echo "Before runing this script: export the environment variable GITLAB_TOKEN with rights to create CI/CD variables"
   echo
   echo "Syntax: "
   echo "$(basename "$0") [-c|h] PROJECT_ID GROUP_ID"
   echo "$(basename "$0") [-d|h] GROUP_ID"
   echo
   echo "options:"
   echo "c     Create Cosign key pair in PROJECT_ID before moving it."
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

if ! [[ -v  GITLAB_TOKEN ]]; then
   echo "[ERROR] the environment variable GITLAB_TOKEN is not set"
   exit 1
fi

if $DELETE_KEY; then
   GROUP_ID=$1
   printf "Deleting key pair from Group: \033[1m%s\033[0m (ID: %s)\n" $(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/${GROUP_ID}" | jq -r '.name') $GROUP_ID 
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables/COSIGN_PRIVATE_KEY" | jq
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables/COSIGN_PASSWORD" | jq
   curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables/COSIGN_PUBLIC_KEY" | jq

else
   PROJECT_ID=$1
   GROUP_ID=$2
   GROUP_NAME=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/${GROUP_ID}" | jq -r '.name')
   PROJECT_NAME=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/${PROJECT_ID}" | jq -r '.name')

   if $GENERATE_KEY; then
     printf "Generating key pair for Project \033[1m%s\033[0m (ID: %s)\n" $PROJECT_NAME  $PROJECT_ID 
     cosign generate-key-pair gitlab://"${PROJECT_ID}"
   fi
   printf "Moving key pair from \033[1m%s\033[0m (ID: %s) to Group \033[1m%s\033[0m (ID: %s)\n" $PROJECT_NAME $PROJECT_ID $GROUP_NAME $GROUP_ID
     
   COSIGN_PRIVATE_KEY=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PRIVATE_KEY" | jq -r '.value')
   COSIGN_PASSWORD=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PASSWORD" | jq -r '.value')
   COSIGN_PUBLIC_KEY=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PUBLIC_KEY" | jq -r '.value')

   printf "Group Variable \033[1m%s\033[0m created\n" $(curl -s -XPOST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables" --form "key=COSIGN_PRIVATE_KEY" --form "value=$COSIGN_PRIVATE_KEY" --form "protected=true" | jq -r '.key')
   printf "Group Variable \033[1m%s\033[0m created\n" $(curl -s -XPOST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables" --form "key=COSIGN_PASSWORD" --form "value=$COSIGN_PASSWORD" --form "protected=true" | jq -r '.key')
   printf "Group Variable \033[1m%s\033[0m created\n" $(curl -s -XPOST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/groups/"${GROUP_ID}"/variables" --form "key=COSIGN_PUBLIC_KEY" --form "value=$COSIGN_PUBLIC_KEY" | jq -r '.key')
   
   printf "Removing key pair from Project \033[1m%s\033[0m (ID: %s)\n" $PROJECT_NAME  $PROJECT_ID

   printf "Project Variable \033[1mCOSIGN_PRIVATE_KEY\033[0m deleted\n" $(curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PRIVATE_KEY")
   printf "Project Variable \033[1mCOSIGN_PASSWORD\033[0m deleted\n" $(curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PASSWORD" | jq)
   printf "Project Variable \033[1mCOSIGN_PUBLIC_KEY\033[0m deleted\n" $(curl -s -XDELETE --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "https://gitlab.com/api/v4/projects/"${PROJECT_ID}"/variables/COSIGN_PUBLIC_KEY" | jq)
fi
