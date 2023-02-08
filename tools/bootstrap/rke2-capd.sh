# This file should be sourced by bootstrap.sh

export MACHINE_IMAGE=${MACHINE_IMAGE:-registry.gitlab.com/t6306/components/docker-images/rke2-in-docker:v1-24-4-rke2r1}
export DOCKER_HOST=${DOCKER_HOST:-unix:///var/run/docker.sock}

echo_b "\U0001F4E6 Pull docker rke2 node machine image " # as capd provider isn't able to deal with authenticated registries

echo ${GITLAB_TOKEN} | docker login -u ${GITLAB_USER} --password-stdin registry.gitlab.com
docker pull ${MACHINE_IMAGE}

