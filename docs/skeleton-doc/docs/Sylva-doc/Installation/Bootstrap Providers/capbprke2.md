---
sidebar_position: 1
---

DRAFT NOTE: Integrate https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster

# Installation Guidelines Using capbprke2

## Overview

This guide provides step-by-step instructions for using the Cluster API Bootstrap Provider RKE2 (capbprke2) to install a Kubernetes cluster. capbprke2 automates the deployment of RKE2 (Rancher Kubernetes Engine 2) clusters using the Cluster API.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
- [Post-Installation Verification](#post-installation-verification)
- [Sylva Integration](#sylva-integration)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## Prerequisites

Before you begin the installation process, ensure that you have the following prerequisites in place:

- A compatible Kubernetes cluster to serve as the management cluster.
- `kubectl` installed and configured to communicate with the management cluster.
- Cluster API installed on the management cluster.
- capbprke2 components available to be deployed on the management cluster.

TODO: Add any Sylva-specific prerequisites that may be necessary.

## Installation Steps

Follow these steps to use capbprke2 for installing your RKE2 cluster:

1. **Install capbprke2 Components**: Deploy the capbprke2 components to your management cluster. This typically involves applying a series of YAML manifests.

    ```shell
    kubectl apply -f capbprke2-components.yaml
    ```

    TODO: Provide the exact location or commands to install the capbprke2 components for Sylva.

2. **Create a Cluster Configuration**: Define your cluster configuration using the capbprke2 template. This will include specifying the desired version of RKE2, the cluster topology, and any other relevant settings.

    ```yaml
    apiVersion: cluster.x-k8s.io/v1alpha4
    kind: Cluster
    metadata:
      name: rke2-cluster
    spec:
      # TODO: Specify the cluster spec for RKE2 using capbprke2
    ```

    TODO: Include a Sylva-specific cluster configuration example.

3. **Deploy the Cluster**: Apply the cluster configuration to the management cluster to start the deployment process.

    ```shell
    kubectl apply -f rke2-cluster.yaml
    ```

4. **Monitor the Deployment**: Watch the cluster components as they are created and verify that all resources reach the desired state.

    ```shell
    kubectl get clusters
    kubectl get kubeadmcontrolplanes
    ```

    TODO: Add any Sylva-specific monitoring or verification steps.

## Post-Installation Verification

After the installation is complete, perform the following steps to verify that the RKE2 cluster is functioning correctly:

1. **Check Cluster Nodes**: Ensure that all the nodes are up and have joined the cluster.

    ```shell
    kubectl get nodes
    ```

2. **Validate Cluster Health**: Run health checks to confirm that the cluster is operational.

    ```shell
    kubectl cluster-info
    ```

    TODO: Provide additional Sylva-specific health checks if necessary.

## Sylva Integration

TODO: Explain how the newly created RKE2 cluster integrates with the Sylva ecosystem, including any additional steps or configurations required.

## Troubleshooting

If you encounter issues during the installation, consider the following troubleshooting steps:

- Verify that all prerequisites are met and that the management cluster is accessible.
- Check the logs of the capbprke2 controller for any errors.
- Ensure that the cluster configuration YAML is correctly formatted and all required fields are populated.

TODO: Include a list of common issues and solutions specific to Sylva and capbprke2.

## FAQ

TODO: Compile a list of frequently asked questions related to the installation process using capbprke2 within the Sylva framework.

---

This document provides a general outline for installing a Kubernetes cluster using the capbprke2 bootstrap provider. The TODO sections should be completed with Sylva-specific details to ensure a comprehensive guide for users.