---
sidebar_position: 1
---

# Bootstrap
# Sylva Bootstrap Script Execution Flow

This Markdown document provides an overview of the execution flow of the Sylva Bootstrap script.

```mermaid
graph TD
    A[Initialization] -->|Source common.sh| B[Validate KUBECONFIG]
    B -->|Non-management cluster| C[Validate input values]
    C -->|Check pivot| D[Set up bootstrap cluster]
    D -->|Ensure Flux is present| E[Validate Sylva units]
    E -->|Validate Sylva units| F[Cleanup and namespace operations]
    F -->|Define source| G[Inject bootstrap values]
    G -->|Apply resources| H[Force reconcile ]
    H -->|Background task| I[Watch bootstrap units and management cluster]
    I -->|Check background task result| J[Watch units installed on management cluster]
    J -->|Final messages and output| K[Sylva is ready]

    K -->|Display information| L[Display management cluster nodes]
    L -->|Display UI access| M[All done]
