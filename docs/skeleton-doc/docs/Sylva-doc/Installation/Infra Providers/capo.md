---
sidebar_position: 1
---

DRAFT NOTE: Integrate https://gitlab.com/sylva-projects/sylva-elements/helm-charts/sylva-capi-cluster

# Installation Guidelines Using capo (Cluster API Provider for OpenStack)

## Overview

This guide provides step-by-step instructions for using the Cluster API Provider for OpenStack (capo) to create Kubernetes clusters on OpenStack. capo allows you to leverage Cluster API's declarative approach for managing Kubernetes clusters within an OpenStack environment.

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

- An OpenStack environment with the necessary permissions to create resources.
- A management cluster where Cluster API and capo components will be deployed.
- OpenStack CLI tools installed and configured.
- `kubectl` installed and configured to communicate with the management cluster.

TODO: Add any Sylva-specific prerequisites that may be necessary.

## Installation Steps

Follow these steps to use `capo` for installing your Kubernetes cluster on OpenStack:

1. **Install capo Components**: Deploy the capo components to your management cluster. This typically involves applying a series of YAML manifests.

    ```shell
    kubectl apply -f capo-components.yaml
    ```

    TODO: Provide the exact location or commands to install the capo components for Sylva.

2. **Create Clouds.yaml**: Ensure you have a `clouds.yaml` file with the credentials and configuration for your OpenStack environment.

    ```yaml
    clouds:
      openstack:
        auth:
          auth_url: "http://<openstack-auth-url>"
          username: "<username>"
          password: "<password>"
          project_id: "<project-id>"
          domain_name: "Default"
        region_name: "RegionOne"
    ```

    TODO: Include a Sylva-specific `clouds.yaml` example if needed.

3. **Create Cluster Configuration**: Define your cluster configuration using the capo template. This will include specifying the OpenStack-specific settings such as flavor, image, and network.

    ```yaml
    apiVersion: cluster.x-k8s.io/v1alpha4
    kind: Cluster
    metadata:
      name: openstack-cluster
    spec:
      # TODO: Specify the cluster spec for OpenStack using capo
    ```

    TODO: Include a Sylva-specific cluster configuration example.

4. **Deploy the Cluster**: Apply the cluster configuration to the management cluster to start the deployment process.

    ```shell
    kubectl apply -f openstack-cluster.yaml
    ```

5. **Monitor the Deployment**: Watch the cluster components as they are created and verify that all resources reach the desired state.

    ```shell
    kubectl get clusters
    kubectl get machines
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

TODO: Explain how the newly created OpenStack Kubernetes cluster integrates with the Sylva ecosystem, including any additional steps or configurations required.

## Troubleshooting

If you encounter issues during the installation, consider the following troubleshooting steps:

- Verify that the `clouds.yaml` file is correctly configured with the right credentials and endpoint.
- Check the logs of the capo controller for any errors.
- Ensure that the OpenStack quotas are sufficient for the resources being created.

TODO: Include a list of common issues and solutions specific to Sylva and `capo`.

## FAQ

TODO: Compile a list of frequently asked questions related to the installation process using `capo` within the Sylva framework.

---

This document provides a general outline for installing a Kubernetes cluster on OpenStack using the `capo` provider. The TODO sections should be completed with Sylva-specific details to ensure a comprehensive guide for users.

