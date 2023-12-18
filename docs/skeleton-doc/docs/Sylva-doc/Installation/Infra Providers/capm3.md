---
sidebar_position: 2
---

DRAFT NOTE: Integrate https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster

# Installation Guidelines Using capm3 (Cluster API Provider Metal3)

## Overview

This guide provides step-by-step instructions for using the Cluster API Provider Metal3 (capm3) to create Kubernetes clusters on bare metal infrastructure. capm3 leverages Metal3's BareMetalHost CRDs to manage the lifecycle of physical machines.

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

- A bare metal infrastructure environment prepared for Metal3 integration.
- A management cluster where Cluster API and capm3 components will be deployed.
- `kubectl` installed and configured to communicate with the management cluster.
- Metal3's BareMetalHost CRDs installed on the management cluster.

TODO: Add any Sylva-specific prerequisites that may be necessary.

## Installation Steps

Follow these steps to use `capm3` for installing your Kubernetes cluster on bare metal:

1. **Install capm3 Components**: Deploy the capm3 components to your management cluster. This typically involves applying a series of YAML manifests.

    ```shell
    kubectl apply -f capm3-components.yaml
    ```

    TODO: Provide the exact location or commands to install the capm3 components for Sylva.

2. **Prepare BareMetalHost Resources**: Define your BareMetalHost resources, including the necessary details about each physical machine, such as BMC credentials, MAC addresses, and boot settings.

    ```yaml
    apiVersion: metal3.io/v1alpha1
    kind: BareMetalHost
    metadata:
      name: baremetal-host-1
    spec:
      # TODO: Specify the BareMetalHost spec for each physical machine
    ```

    TODO: Include a Sylva-specific BareMetalHost resource example.

3. **Create Cluster Configuration**: Define your cluster configuration using the capm3 template. This will include specifying the cluster infrastructure settings tailored for bare metal.

    ```yaml
    apiVersion: cluster.x-k8s.io/v1alpha4
    kind: Cluster
    metadata:
      name: metal3-cluster
    spec:
      # TODO: Specify the cluster spec for bare metal using capm3
    ```

    TODO: Include a Sylva-specific cluster configuration example.

4. **Deploy the Cluster**: Apply the cluster configuration to the management cluster to start the deployment process.

    ```shell
    kubectl apply -f metal3-cluster.yaml
    ```

5. **Monitor the Deployment**: Watch the cluster components as they are created and verify that all resources reach the desired state.

    ```shell
    kubectl get clusters
    kubectl get baremetalhosts
    ```

    TODO: Add any Sylva-specific monitoring or verification steps.

## Post-Installation Verification

After the installation is complete, perform the following steps to verify that the Kubernetes cluster is functioning correctly:

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

TODO: Explain how the newly created bare metal Kubernetes cluster integrates with the Sylva ecosystem, including any additional steps or configurations required.

## Troubleshooting

If you encounter issues during the installation, consider the following troubleshooting steps:

- Verify that the BareMetalHost resources are correctly defined and that the management cluster can communicate with the BMCs.
- Check the logs of the capm3 controller for any errors.
- Ensure that the physical machines meet the requirements for running Kubernetes.

TODO: Include a list of common issues and solutions specific to Sylva and `capm3`.

## FAQ

TODO: Compile a list of frequently asked questions related to the installation process using `capm3` within the Sylva framework.

---

This document provides a general outline for installing a Kubernetes cluster on bare metal infrastructure using the `capm3` provider. The TODO sections should be completed with Sylva-specific details to ensure a comprehensive guide for users.

