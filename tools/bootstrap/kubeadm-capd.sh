# This file should be sourced by bootstrap.sh

export MACHINE_IMAGE=${MACHINE_IMAGE:-registry.gitlab.com/t6306/components/capi-bootstrap/kindest/node:v1.25.0-cni}
export DOCKER_HOST=${DOCKER_HOST:-unix:///var/run/docker.sock}

echo_b "\U0001F4E6 Pull docker kindest/node machine image " # as capd provider isn't able to deal with authenticated registries

echo ${GITLAB_TOKEN} | docker login -u ${GITLAB_USER} --password-stdin registry.gitlab.com
docker pull ${MACHINE_IMAGE}

