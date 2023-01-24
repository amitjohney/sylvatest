#!/bin/sh

echo "This script should be overwritten, otherwise it won't do anything but printing this message"


#echo "Retrieve target cluster kubeconfig"
#kubectl get secret management-cluster-kubeconfig -o jsonpath='{.data.value}' | base64 -d > management-cluster-kubeconfig
#
#echo "Wait for cluster and machines to be ready as it is a required condition to move"
#kubectl wait --for condition=ControlPlaneReady --timeout 600s --all cluster
#kubectl wait --for condition=NodeHealthy --timeout 600s --all machine
#
#echo "Freeze reconciliation on Kustomisations in source cluster that related to the management cluster"
#kubectl annotate kustomizations -l suspend-on-pivot=yes kustomize.toolkit.fluxcd.io/reconcile=disabled --overwrite
#
#echo "Move cluster definitions from source to target cluster"
#clusterctl move --kubeconfig $KUBECONFIG --to-kubeconfig management-cluster-kubeconfig
