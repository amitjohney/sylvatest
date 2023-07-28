#!/bin/sh

./bin/kind delete clusters sylva
./tools/openstack-cleanup.sh my-cloud
rm management-cluster-kubeconfig
