# Opni in Sylva
1. [Introduction](#introduction)
2. [Opni architecture](#opni-architecture)
3. [How to enable opni in Sylva](#how-to-enable-opni-in-sylva)
4. [How to configure opni in Sylva](#how-to-configure-opni-in-sylva)
    - [Opni example configurations](#opni-example-configurations)
        - [Monitoring backend authentication using Sylva's Keycloak as IDP](#monitoring-backend-authentication-using-sylvas-keycloak-as-idp)
            - [Manually mount Sylva CA certificate](#manually-mount-sylva-ca-certificate)
            - [Configuring `insecureSkipVerify`](#configuring-insecureskipverify)
        - [Monitoring backend authentication using an external IDP](#monitoring-backend-authentication-using-an-external-idp)
            - [IDP with a discovery endpoint](#idp-with-a-discovery-endpoint)
            - [IDP without a discovery endpoint](#idp-without-a-discovery-endpoint)
5. [Opni usage](#opni-usage)
    - [Enabling the Monitoring backend](#enabling-the-monitoring-backend)
    - [Enabling the Logging backend](#enabling-the-logging-backend)
    - [Adding additional Opni agents](#adding-additional-opni-agents)
6. [Known Problems](#known-problems)
    - [Prometheus provider is not working for Monitoring backend](#prometheus-provider-is-not-working-for-monitoring-backend)
    - [Opni Logging backend Controlplane configuration](#opni-logging-backend-controlplane-configuration)
7. [Troubleshooting](#troubleshooting)

# Introduction

Opni is an optional component of the Sylva stack that is responsible for multi-cluster and multi-tenant observability. It simplifies the process of creating and managing backends, agents, and data related to logging, monitoring, and tracing. 

With built-in AIOps, Opni allows users to swiftly detect anomalous activities in their data.

This document covers:
1. An overview of Opni's architecture
2. How one can can enable Opni as a `sylva-unit` in order to monitor **logs, metrics and traces** of clusters deployed by Sylva
    - Examples of different Opni setups
3. How to use Opni once deployed

If you want to dig deeper, take a look at the following links to the official upstream documentation and project.

Links to the upstream official documentation:

- [Opni user guide](https://opni.io)

Links to the upstream repositories:

- [Opni](https://github.com/rancher/opni)
- [Opni helm charts](https://github.com/rancher/opni/tree/charts-repo/charts)

# Opni architecture
The opni project aims at extending existing open source solutions so that it is easier to manage the **logs, metrics and traces** (what Opni calls "observability data") of a multi-cluster setup.

From Opni's docs:
> Observability data comes in the form of **logs, metrics and traces**. The collection and storage of observability data is handled by observability backends and agents. AIOps helps makes sense of this observability data. Opni comes with all these nuts and bolts and can be used to self monitor a single cluster or be a centralized observability data sink for multiple clusters.

![alt text](https://opni-public.s3.us-east-2.amazonaws.com/v06_high_level_arch.png)

The above diagram illustrates how Opni's multi-cluster observability works.

On the **Upstream Opni Cluster** (in Sylva's case this would be the `management-cluster`), Opni is deployed with its full range of components. This includes:
1. **Opni Agent** - Observability agents are software that collects observability data (logs, metrics, traces, and events) from their host and sends it to an observability backend. Observability data that will be sent depends on what `backends` were enabled for this agent in the **Opni dashboard**
2. **Opni Backends** - Observability backends receive and store various data types. Opni, designed with Kubernetes in mind, builds on popular open-source tools to serve as backends. Although these backends can be challenging to set up, Opni streamlines their creation and management. Currently available backends:
    - Opni Logging - enhances [Opensearch](https://opensearch.org) for easy searching, visualization, and analysis of logs, traces, and Kubernetes events
    - Opni Monitoring - extends [Cortex](https://cortexmetrics.io) for multi-cluster, long-term storage of Prometheus metrics
3. **AIOps** - AIOps involves the application of AI and machine learning to IT and observability data. Opni AIOps features include:
    - Log anomaly detection:
        - Pretrained models for [Kubernetes control plane](https://kubernetes.io/docs/concepts/overview/components/), [Rancher](https://www.rancher.com/why-rancher), and [Longhorn](https://longhorn.io)
4. **Alerting and SLOs** - Creating triggers and reliability targets for services allows you to utilize your data effectively and make informed decisions regarding software operations. Opni alerting enables this through its alerting and SLO interface.

Microservices responsible for managing these components include:
1. `opni-gateway` - Serves as an observability backend for `opni-agents` and offers the **Opni dashboard** through which all Opni components can be managed
2. `opni-manager` - Responsible for setting up the `opni-gateway` and anyother opni related microservice/resource

On the **Downstream Opni Cluster(s)** (in Sylva's case this would be the `workload-cluster`) only the `opni-agent` is deployed. It will be directly connected/registered to the `opni-gateway` running on the upstream cluster using **certificate pinning**. After connecting to the gateway, and if you have enabled any backends for this specific agent, it will begin sending observability data to the `opni-gateway`.

# How to enable opni in Sylva

In order to deploy Opni on a Sylva's `management-cluster`, you must enable the `opni` unit in the `environment-values/<env>/values.yaml` file for the Sylva environment of your choosing.

If you would like to monitor observability data for more than the `management-cluster`, you would need to enable the `cert-manager` unit for the `workload-cluster`. This will ensure that `opni-agents` can successfully be deployed there, as they require `cert-manager` to be deployed as a prerequisite.

```yaml
# Example for kubeadm-capd environment deployment
units:
  ...
  workload-cluster:
  enabled: true
  helmrelease_spec:
    values:
      units:
        # config only needed if opni-agents will be deployed on the 
        # workload cluster
        cert-manager:
          enabled: true
  opni:
    enabled: true

cluster:
  ...
  # custom opni configuration, covered later in the document
  opni: {}
```

# How to configure opni in Sylva
Below you can find a table showing all possible configuration values enabled for the `opni` unit (both optional and required). In general the only configuration that needs to be done is OpenID configuration for Opni's **Monitoring** backend. 

List of **required** configuration properties:
| Property                                          | Description                                                                               | Example                             |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------- |
| **opni.gateway.auth.openid.discovery.path**       | Relative path at which to find the openid discovery configuration                         |`"/.well-known/openid-configuration"`|
| **opni.gateway.auth.openid.discovery.issuer**     | The openid provider's Issuer identifier                                                   |`"https://foo.bar.com/"`             |
| **opni.gateway.auth.openid.identifyingClaim**     | The ID Token claim that will be used to identify users to the **Monitoring** backend       |`"sub"`                              |
| **opni.gateway.auth.openid.clientID**             | The unique client identifier for an account on the OpenID Connect provider                |`""`                                 |
| **opni.gateway.auth.openid.clientSecret**         | The unique client secret for an account on the OpenID Connect provider                    |`""`                                 |
| **opni.gateway.auth.openid.scopes**               | OAuth scopes that will be requested by the client                                         |`["openid", "profile", "email"]`     |
| **opni.gateway.auth.openid.roleAttributePath**    | Configuration that maps permissions of the OpenID connect provider user to Opni's **Monitoring** backend. More info [here](https://grafana.com/docs/grafana/v9.0/setup-grafana/configure-security/configure-authentication/generic-oauth/#roles)| `contains(roles[*], 'admin') && 'Admin'`|
| **opni.gateway.auth.openid.wellKnownConfiguration.issuer**| The openid provider's Issuer identifier                                           |`""`                                 |
| **opni.gateway.auth.openid.wellKnownConfiguration.authorization_endpoint**| URL where the client will be sent to authentitcate                |`""`                                 |
| **opni.gateway.auth.openid.wellKnownConfiguration.token_endpoint** | URL from which clients will obtain access and ID tokens from the OpenID provider|`""`                          |
| **opni.gateway.auth.openid.wellKnownConfiguration.userinfo_endpoint** | URL that will be used for retrieving information about the logged in user |`""`                             |
| **opni.gateway.auth.openid.wellKnownConfiguration.jwks_uri**| URL for the [JSON Web Key Sets](https://auth0.com/docs/secure/tokens/json-web-tokens/json-web-key-sets) of the OpenID provider |`""`|

> **_NOTE:_**  `opni.gateway.auth.openid.discovery` and `opni.gateway.auth.openid.wellKnownConfiguration` are mutually exclusive. If the openid provider has a discovery endpoint, it should be configured in the discovery field, otherwise the well-known configuration fields can be set manually.

> **_NOTE:_**  `opni.gateway.auth.openid.clientID` and `opni.gateway.auth.openid.clientSecret` should **NOT** be set in the `values.yaml` of the Sylva environment dir. Instead they should be set in the `secrets.yaml` file of the same directory. That way you will not expose sensitive data in your repo.


List of **optional** configuration properties:
| Property                                          | Description                                                                                       | Default                        |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------- | -----------------------------  |
| **opni.volumes**                                  | `opni-manager` additional volumes                                                                 |`[]`                            |
| **opni.volumeMounts**                             | `opni-manager` additional volumesMounts                                                           |`[]`                            |
| **opni.gateway.extraVolumeMounts**                | `opni-gateway` additional volumes and volumeMounts                                                |`[]`                            |
| **opni.gateway.serviceType**                      | Service type for the `opni` service                                                               |`"NodePort"`                    |
| **opni.gateway.serviceAnnotations**               | Service annotations for the `opni` service                                                        |`{}`                            |
| **opni.gateway.external_hostname**                | Base hostname from which the logging, monitoring and dashboard Ingress records will be made       |`"<cluster_external_domain>"`                  |
| **opni.gateway.auth.provider**                    | Authentication provider for Opni's **Monitoring** backend (currently only "openid" is supported)|`"openid"`                      |
| **opni.gateway.auth.useInternalKeycloak**         | Use Sylva's internal Keycloak as an IDP for Opni's **Monitoring** backend                                     |`false`                         |
| **opni.gateway.auth.openid.insecureSkipVerify**   | Disable TLS certificate verification when communicating with the OpenID Connect issuer that Opni is using for the **Monitoring** backend authentication                                          |`false`                         |
| **opni.monitoring.external_hostname**             | Hostname for the monitoring Ingress record                                                        |`"grafana.opni.<cluster_external_domain>"` |
| **opni.logging.external_hostname**                | Hostname for the logging Ingress record                                                           |`"logging.opni.<cluster_external_domain>"` |
| **opni.dashboard.external_hostname**              | Hostname for the dashboard Ingress record                                                         |`"dashboard.opni.<cluster_external_domain>"` |
| **opni.opni_agent.kube_prometheus_stack.enabled** | Deploy kube-prometheus-stack with the `opni-agent`  that will be deployed on the `management-cluster`                           |`true`                         |
| **opni.opni_prometheus_crd.enabled**              | Deploy Prometheus CRDs (should be **false** if `opni.opni_agent.kube_prometheus_stack` is enabled)  |`false`                        |

## Opni example configurations
This section aims to show examples of how to configure Opni's **required** values, so that you could deploy Opni on a `management` and `workload` clusters.

### Monitoring backend authentication using Sylva's Keycloak as IDP
Sylva's [keycloak](https://gitlab.com/sylva-projects/sylva-core/-/tree/main/kustomize-units/keycloak) unit can be used in Opni's **Monitoring** backend OpenID authentication. Below you can find configuration steps on how to achieve this.

Config in `environment-values/<env>/values.yaml`:
```yaml
# Example for kubeadm-capd environment deployment
units:
  ...
  workload-cluster:
  enabled: true
  helmrelease_spec:
    values:
      units:
        # config only needed if opni-agents will be deployed on the 
        # workload cluster
        cert-manager:
          enabled: true
  opni:
    enabled: true
  keycloak:
    enabled: true
  ...

cluster:
  ...
  opni:
    gateway:
      auth:
        useInternalKeycloak: true
  ...
```

By setting `opni.gateway.auth.useInternalKeycloak: true` the following happens:
1. A Keycloak client is automatically created in the Keycloak applicaiton.
2. A Keycloak user is automatically created in the Keycloak applicaiton. If you want to use different users, you can use the created user as a template.
3. Sylva's CA cert is mounted to the `opni-manager` and `opni-gateway` microservices. This is needed in order for the microservices to be able to call Sylva's Keycloak url.
4. The `clientID` and `clientSecret` will be automatically passed to Opni's configuration
5. All `openid` configuration will be automatically filled and passed to Opni's configuration

> **_NOTE:_** You can see the `username` of the created Keycloak user form the Keycloak Admin UI. The `password` for the user is the one passed in the `environment-values/<env>/secrets.yaml` file under `cluster.admin_password`. If you have not provided a password, then a random password will be generated. Randomly generated password can be retrieved by doing `kubectl get secrets sylva-units-values-debug -n default -o template="{{ .data.values }}" | base64 -d | grep admin_password` in the `management-cluster`. The user has `admin` privileges in Opni's **Monitoring** backend (Grafana).

> **_NOTE:_**  The default values for `openid` are as follows:
> 1. `opni.gateway.auth.openid.identifyingClaim: "sub"`
> 2. `opni.gateway.auth.openid.insecureSkipVerify: false`
> 3. `opni.gateway.auth.openid.scopes: ["openid", "profile", "email", "offline_access", "roles"]`
> 4. `opni.gateway.auth.openid.roleAttributePath: "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'"`
> 5. `opni.gateway.auth.openid.wellKnownConfiguration.issuer: "https://keycloak.sylva/realms/sylva"`
> 6. `opni.gateway.auth.openid.wellKnownConfiguration.authorization_endpoint: "https://keycloak.sylva/realms/sylva/protocol/openid-connect/auth"`
> 7. `opni.gateway.auth.openid.wellKnownConfiguration.token_endpoint: "https://keycloak.sylva/realms/sylva/protocol/openid-connect/token"`
> 8. `opni.gateway.auth.openid.wellKnownConfiguration.userinfo_endpoint: "https://keycloak.sylva/realms/sylva/protocol/openid-connect/userinfo"`
> 9. `opni.gateway.auth.openid.wellKnownConfiguration.jwks_uri: "https://keycloak.sylva/realms/sylva/protocol/openid-connect/certs"`
> 
>Should you need a different `identifyingClaim` you can pass it to the `environment-values/<env>/secrets.yaml` file configuration as follows: `cluster.opni.gateway.auth.openid.identifyingClaim: "foo"`.
> The `opni.gateway.auth.openid.roleAttributePath` and `opni.gateway.auth.openid.scopes` are hardcoded based on the created Keycloak client and user which were created following Grafana's [docs](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/).
> The `wellKnownConfiguration` was retrieved from the `https://keycloak.sylva/realms/sylva/.well-known/openid-configuration` url.


> **_WARNING:_** One **manual** step would need to be performed before using Sylva's Keycloak as IDP for Opni's **Monitoring** backend.. Sylva's CA certificate must be manually mounted to the Grafana pod that will be created once the **Monitoring** backend is enabled. Sadly with the current version of Opni this cannot be automated before hand, as the Grafana pod is created dynamically and preconfiguration is not possible at the moment (this will be fixed in future versions of Opni). How to do this is covered below.

#### Manually mount Sylva CA certificate

Once you have enabled Opni's **Monitoring** backend (but not yet installed it on the agent) a `MonitoringCluster` resource will be created in the `opni` unit namespace. This resource holds configurations for the **Grafana pod** that will be deployed in the `opni` unit namespace by Opni's infrastructure. You can patch this resource with extra **volumes** and **volumeMounts** containing Sylva's CA certificate.

Patch steps:

(1) Save patch configurations to a file (`patch.yaml`): 
```yaml
spec:
  grafana:
    deployment:
      extraVolumeMounts:
      - mountPath: /etc/ssl/certs/ca.crt
        name: sylva-ca
        readOnly: false
        subPath: ca.crt
      extraVolumes:
      - name: sylva-ca
        secret:
          secretName: sylva-ca.crt
```
The `sylva-ca.crt` secret is automatically created and present in the namespace where the `opni` unit is deployed.

(2) Apply patch to the `MonitoringCluster` resource:
```bash
kubectl patch monitoringcluster opni -n opni --patch-file patch.yaml --type=merge
```

By doing this Opni's infrastructure will update **Grafana's pod** with the aforementioned configuration. After this has been done you can continue to configure your Opni Monitoring `RBAC` roles and rolebinding, and installing the `Monitoring` backend to the `management-cluster` agent.

#### Configuring `insecureSkipVerify`

For faster development/testing of Opni's **Monitoring** backend using Sylva's Keycloak authentication, you can set the `opni.gateway.auth.openid.insecureSkipVerify` to `true`.

By doing this you would not have to manually mount Sylva's CA certificate to the Grafana pod.

Config in `environment-values/<env>/values.yaml`:
```yaml
# Example for kubeadm-capd environment deployment
units:
  ...
  workload-cluster:
  enabled: true
  helmrelease_spec:
    values:
      units:
        # config only needed if opni-agents will be deployed on the 
        # workload cluster
        cert-manager:
          enabled: true
  opni:
    enabled: true
  keycloak:
    enabled: true
  ...

cluster:
  ...
  opni:
    gateway:
      auth:
        useInternalKeycloak: true
        openid:
          insecureSkipVerify: true
  ...
```

After Opni has deployed, you can continue to enable the **Monitoring** backend without any manual steps.

> **_NOTE:_** It is not advisable to use `insecureSkipVerify` on production environments.

### Monitoring backend authentication using an external IDP 
#### IDP with a discovery endpoint
If you want to use an external identity provider and the provider has a discovery endpoint, then your configuration in `environment-values/<env>/values.yaml` should be:

```yaml
# Example for kubeadm-capd environment deployment
units:
  ...
  workload-cluster:
  enabled: true
  helmrelease_spec:
    values:
      units:
        # config only needed if opni-agents will be deployed on the 
        # workload cluster
        cert-manager:
          enabled: true
  opni:
    enabled: true
  ...

cluster:
  ...
  opni:
    gateway:
      auth:
        openid:
          discovery:
            path: "" # Example: "/.well-known/openid-configuration"
            issuer: "" # Example: "https://foo.bar.com/"
          identifyingClaim: "" # Example: "nickname", "sub", "email", etc.
          scopes: [] # Example: ["openid", "profile", "email"]
          roleAttributePath: "" # Example: "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'"
  ...
```

Your `secrets.yaml` file should look like this:
```yaml
cluster:
  opni:
    gateway:
      auth:
        openid:
          clientID: "foo"
          clientSecret: "bar" 
```

#### IDP without a discovery endpoint
If you want to use an external identity provider and the provider does not have a discovery endpoint, then your configuration in `environment-values/<env>/values.yaml` should be:
```yaml
# Example for kubeadm-capd environment deployment
units:
  ...
  workload-cluster:
  enabled: true
  helmrelease_spec:
    values:
      units:
        # config only needed if opni-agents will be deployed on the 
        # workload cluster
        cert-manager:
          enabled: true
  opni:
    enabled: true
  ...

cluster:
  ...
  opni:
    gateway:
      auth:
        openid:
          identifyingClaim: "" # Example: "nickname", "sub", "email", etc.
          scopes: [] # Example: ["openid", "profile", "email"]
          roleAttributePath: "" # Example: "contains(roles[*], 'admin') && 'Admin' || contains(roles[*], 'editor') && 'Editor' || 'Viewer'"
          wellKnownConfiguration:
            issuer: ""
            authorization_endpoint: ""
            token_endpoint: ""
            userinfo_endpoint: ""
            jwks_uri: ""
  ...
```
Your `secrets.yaml` file should look like this:
```yaml
cluster:
  opni:
    gateway:
      auth:
        openid:
          clientID: "foo"
          clientSecret: "bar" 
```

# Opni usage
This section covers how to use Opni inside of a Sylva cluster deployemnt. It aims to only cover Sylva specific configurations. For additional info on Opni's usage plese refer to their [docs](https://opni.io).

> **_NOTE:_** This section assumes that your **Opni dashboard** url resolves to the value of the following template: `{{ .Values.cluster.display_external_ip }}`. The property can be viewed from th `values.yaml` file of the Sylva helm chart.

## Enabling the Monitoring backend

1. Navigate to the **Opni dashboard**, if you have not configured a different host, it should be on the following endpoint: `https://dashboard.opni.sylva/`
2. Navigate to the **Monitoring** backend and click **Install**
    - Storage:
        - Mode should be `Standalone`
        - Storage type should be `Filesystem`
    - Grafana:
        - The Grafana hostname should be `grafana.opni.sylva`. If you have changed the `opni.gateway.external_hostname` then the value would be `grafana.<your_hostname>`. If you have changed the `opni.monitoring.external_hostname`, then the value would be whatever you have provided there.
3. Install

This will create a `MonitoringCluster` resource from which a Grafana pod will be deployed. Once the Grafana pod has successfully deployed you will see the `"Monitoring is currently installed on the cluster"` message which indicates that there were no issues.

From here on you can proceed to setup monitoring `RBAC` roles and role bindings for users. As described in the Opni [docs](https://opni.io/installation/opni/backends#access-control).

An example of a correctly setup `RBAC` config would include:
1. RBAC role with a label setup. Example: `view=production`
2. RBAC role binding that utilizes the created role and has for a subject whatever you have provided under `opni.gateway.auth.openid.identifyingClaim`. Example: 
    - `opni.gateway.auth.openid.identifyingClaim: "sub"`
    - Subject in role binding would then be: `e06eae79-f23f-4561-9e0e-ddae736b3e73` ("sub" value should be taken for your user from your OpenID provider)
3. Label agents with the created role
    - Navigate to `Agents` in the `Opni Dashboard` and click edit on the agent you want to label
    - Click add label
    - Pass the created role label value. Example: `view=production`
4. Go back to the **Monitoring** backend and click install for the agent that you just labeled. Note: use OpenTelemetry as a provider, Prometheus is currently not working.

After that you can safely navigate to `https://grafana.opni.sylva` and login with the user you have configured in your OpenID provider.

## Enabling the Logging backend

1. Navigate to the **Opni dashboard**, if you have not configured a different host, it should be on the following endpoint: `https://dashboard.opni.sylva/`
2. Navigate to the **Logging** backend and click **Install**
    - Enable `Ingest Pods`
    - Enable `Controlplane Pods`. Set replicas to `3`

After that you can refer to the Opni [docs](https://opni.io/installation/opni/backends) for further information.

After the installation has completed you can access Opni's Logging backend on the `https://logging.opni.sylva`url.

## Adding additional Opni agents

1. Navigate to the **Opni Dashboard**, if you have not configured a different host, it should be on the following endpoint: `https://dashboard.opni.sylva/`
2. Navigate to **Agents** and click **Add**
3. From there open `Manual Install Information` and copy the `Bootstrap Token` and `Certificate Pin`
4. Open Rancher UI 
    - Navigate to the local cluster 
        - Cluster -> Nodes -> Copy Node IP
        - Service Discovery -> Services -> Copy `opni` service NodePort value. By default the `opni` service is of type `NodePort`. If you have selected something else for the `opni.gateway.serviceType` value, then these steps might differ.
    - Navigate to the `workload-cluster` and follow the `opni-agent` installation steps from the Opni [docs](https://opni.io/installation/opni_agent).
        - Provide `Bootstrap Token` and `Certificate Pin` from point (3)
        - `Gateway URL` would be `<node_ip>:<opni-svc-nodePort>`. Example: `172.18.0.4:31621`

After the installation has finished you should see the agent in the `Opni Dashboard` under `Agents`

# Known Problems

## Prometheus provider is not working for Monitoring backend
Currently collecting monitoring data with Prometheus is not working (see https://github.com/rancher/opni/issues/1540). In order for Opni's Monitoring backend to work `OpenTelemetry` metrics would have to be enabled (which is done by a click of a button).

## Opni Logging backend Controlplane configuration
In order for Opni's `Logging` backend to function as expected, when configuring it, you would need to pass a replica number for the `Controlplane Pods` of no lower than '3'. Any lower than this value will cause the `Logging` backend to not work as expected.

# Troubleshooting 
In case of issues there may be a wide range of reasons.

The following commands might help you in determining the cause of the problem:
```bash
# Check the logs of the opni-manager
kubectl logs deployment/opni-manager -n opni -c manager

# Check the logs of the opni-gateway 
kubectl logs deployment/opni-gateway -n opni

# Check the logs of the opni-agent
kubectl logs statefulset/opni-agent -n opni

# You can also use the 'opni' binary that is present in the
# opni-gateway pod for further debugging
kubectl exec -it opni-gateway-865c7c76d7-vdjx9 -n opni -- opni -h
# or you can directly ssh into the pod and use 'opni' binary from there
kubectl exec -it <opni-gateway-pod-name> -n opni -- /bin/bash

# Check if the configuration in the Gateway resource is the 
# same as the one you have provided in the env values.yaml file
kubectl get gateway opni-gateway -o yaml

### If Monitoring backed is enabled ###
# Check the data in the MonitoringCluster resouce
kubectl get monitoringcluster opni -n opni -o yaml

# Check Grafana logs
kubectl logs deployment/grafana -n opni

### If Logging backend is enabled ###
# Check data of the LoggincCluster resource
kubectl get loggingcluster -o yaml -n opni

# Check data of OpenSearchCluster resource
kubectl get opensearchcluster opni -o yaml -n opni

# Check ingest logs
kubectl logs statefulset/opni-ingest -n opni

# Check data logs
kubectl logs statefulset/opni-data -n opni

# Check controlplane logs
kubectl logs statefulset/opni-controlplane -n opni
```