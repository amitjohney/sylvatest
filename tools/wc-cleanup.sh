#!/bin/bash

if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
    echo "Usage: ./wc-cleanup.sh <Workload-cluster-name> <(optionally)cluster_object_name>"
fi

WORKLOAD_CLUSTER=$1
if [[ -z "$2" ]]; then
  CLUSTER="cluster"
else
  CLUSTER=$2
fi

if [[ -z "$1" ]]; then
  echo "Namespace is not defined"
else
  echo $WORKLOAD_CLUSTER - $CLUSTER
  source bin/env
  export KUBECONFIG=management-cluster-kubeconfig
  flux suspend --all ks -n $CLUSTER
  flux suspend --all hr -n $CLUSTER
  kubectl patch  -n $WORKLOAD_CLUSTER clusters.cluster.x-k8s.io $CLUSTER --type merge -p '{"spec":{"paused": false}}'
  kubectl delete -n $WORKLOAD_CLUSTER hr $CLUSTER
  kubectl delete -n $WORKLOAD_CLUSTER heatstacks heatstack-capo-cluster-resources
  kubectl delete ns $WORKLOAD_CLUSTER
fi
