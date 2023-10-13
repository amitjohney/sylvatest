#!/bin/bash

set -e
set -o pipefail

echo "-- Inject unrestricted PSP"

cat <<EOF >>/tmp/unrestricted-psp.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
name: unrestricted-psp
namespace: cattle-fleet-system
rules:
- apiGroups:
- extensions
resourceNames:
- system-unrestricted-psp
resources:
- podsecuritypolicies
verbs:
- use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
name: unrestricted-psp
namespace: cattle-fleet-system
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: Role
name: unrestricted-psp
subjects:
- kind: ServiceAccount
name: fleet-controller
EOF

kubectl apply -f /tmp/unrestricted-psp.yaml

echo "-- purge fleet-job pods"
kubectl -n cattle-fleet-system delete pod -l app=fleet-job

echo "-- All done"
