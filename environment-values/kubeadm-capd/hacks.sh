# This file contains ad-hoc hacks for this environment, it will be sourced by bootstrap.sh and apply.sh

export MACHINE_IMAGE=${MACHINE_IMAGE:-registry.gitlab.com/t6306/components/capi-bootstrap/kindest/node:v1.25.0-cni}
export DOCKER_HOST=${DOCKER_HOST:-unix:///var/run/docker.sock}

echo_b "\U0001F4E6 Pull docker kindest/node machine image " # as capd provider isn't able to deal with authenticated registries

source $(dirname ${BASH_SOURCE[0]})/git-secrets.env

echo ${password} | docker login -u ${username} --password-stdin registry.gitlab.com
docker pull ${MACHINE_IMAGE}

