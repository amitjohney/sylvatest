#!/bin/bash

set -ue
set -o pipefail

TEMPLATE_TYPES_CR="
KubeadmConfigTemplates
RKE2ConfigTemplates
DockerMachineTemplates
VSphereMachineTemplates.*cluster.x-k8s.io
OpenStackMachineTemplates
Metal3MachineTemplates
"

for TEMPLATE_CR in ${TEMPLATE_TYPES_CR[@]}; do

    if kubectl api-resources | grep -i $TEMPLATE_CR > /dev/null ; then

        # Transform the .* used for matching kubectl api-resource, into a plain '.'
        # (see VSphereMachineTemplates.*cluster.x-k8s.io above)
        TEMPLATE_RESOURCE=${TEMPLATE_CR/\*/}

        # Only for (Docker|VSphere|OpenStack|Metal3)MachineTemplates resources
        if [[ $TEMPLATE_RESOURCE =~ .*MachineTemplate ]]; then

            # Extract cloned template resource type from template type (eg. OpenStackMachine out of OpenStackMachineTemplate)
            CLONED_TEMPLATE_RESOURCE="${TEMPLATE_RESOURCE/Template}"

            echo -e "\n Inspecting all $TEMPLATE_RESOURCE resource instances/names for
- usage as (RKE2ControlPlane.spec|KubeadmControlPlane.spec.machineTemplate).infrastructureRef.name
- usage as (MachineDeployment|MachineSet).spec.template.spec.infrastructureRef.name
- presence of $CLONED_TEMPLATE_RESOURCE resources having the annotation cluster.x-k8s.io/cloned-from-name=<$TEMPLATE_RESOURCE resource instance>"

        # Only for (Kubeadm|RKE2)ConfigTemplate resources
        elif [[ $TEMPLATE_RESOURCE =~ .*ConfigTemplate ]]; then

            echo -e "\n Inspecting all $TEMPLATE_RESOURCE resource instances/names for
- usage as (MachineDeployment|MachineSet).spec.template.spec.bootstrap.configRef.name"

        fi

        # Get all namespaces in which template resources of a particular type are seen (in which Sylva clusters are deployed)
        for TARGET_NAMESPACE in $(kubectl get $TEMPLATE_RESOURCE --all-namespaces -o=custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace --no-headers | awk '{print $2}' | sort | uniq); do

            # Get all template resources older than 5 minutes (eg. name of all OpenStackMachineTemplates from a ns with .metadata.creationTimestamp > 300s)
            # and only continue if list is not empty
            TEMPLATE_RESOURCE_INSTANCE_LIST=$(kubectl -n "$TARGET_NAMESPACE" get "$TEMPLATE_RESOURCE" -o json | jq -r --argjson timestamp 300 '.items[] | select (.metadata.creationTimestamp | sub("\\..*";"Z") | sub("\\s";"T") | fromdate < now - $timestamp).metadata.name')

            if [ -z "$TEMPLATE_RESOURCE_INSTANCE_LIST" ]; then
                echo -e "\n\t All $TEMPLATE_RESOURCE inside namespace $TARGET_NAMESPACE are newer than 5 minutes \n"
                kubectl -n "$TARGET_NAMESPACE" get "$TEMPLATE_RESOURCE" -o=custom-columns=KIND:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace,AGE:.metadata.creationTimestamp
                continue
            fi
            echo -e "\n   Garbage collecting CAPI template resources for namespace $TARGET_NAMESPACE"
            # Iterate over template resource instances (eg. each OpenStackMachineTemplate)
            for TEMPLATE_RESOURCE_INSTANCE in $TEMPLATE_RESOURCE_INSTANCE_LIST; do

                : > /tmp/template_resources_consumers.txt
                could_be_removed="true"

                # Only for (Docker|VSphere|OpenStack|Metal3)MachineTemplates resources
                if [[ $TEMPLATE_RESOURCE =~ .*MachineTemplate ]]; then

                    # Check there's no KubeadmControlPlane.spec.machineTemplate.infrastructureRef.name
                    # or RKE2ControlPlane.spec.infrastructureRef.name usage for the template resource instance
                    if kubectl api-resources | grep -i KubeadmControlPlane > /dev/null ; then
                        kubectl -n "$TARGET_NAMESPACE" get KubeadmControlPlane -o=custom-columns=KIND:.kindNAME:.metadata.name,INFRASTRUCTURE_REF_NAME:.spec.machineTemplate.infrastructureRef.name,INFRASTRUCTURE_REF_KIND:.spec.machineTemplate.infrastructureRef.kind --no-headers >> /tmp/template_resources_consumers.txt
                    fi
                    if kubectl api-resources | grep -i RKE2ControlPlane > /dev/null; then
                        kubectl -n "$TARGET_NAMESPACE" get RKE2ControlPlane -o=custom-columns=KIND:.kind,NAME:.metadata.name,INFRASTRUCTURE_REF_NAME:.spec.infrastructureRef.name,INFRASTRUCTURE_REF_KIND:.spec.infrastructureRef.kind --no-headers >> /tmp/template_resources_consumers.txt
                    fi

                    # Check there's no MachineSet.spec.template.spec.infrastructureRef.name usage for the template resource instance
                    kubectl -n "$TARGET_NAMESPACE" get MachineSet -o=custom-columns=KIND:.kind,NAME:.metadata.name,INFRASTRUCTURE_REF_NAME:.spec.template.spec.infrastructureRef.name,INFRASTRUCTURE_REF_KIND:.spec.template.spec.infrastructureRef.kind --no-headers >> /tmp/template_resources_consumers.txt

                    # Check there's no MachineDeployment.spec.template.spec.infrastructureRef.name usage for the template resource instance
                    kubectl -n "$TARGET_NAMESPACE" get MachineSet -o=custom-columns=KIND:.kind,NAME:.metadata.name,INFRASTRUCTURE_REF_NAME:.spec.template.spec.infrastructureRef.name,INFRASTRUCTURE_REF_KIND:.spec.template.spec.infrastructureRef.kind --no-headers >> /tmp/template_resources_consumers.txt

                    while read INFRASTRUCTURE_CONSUMER_KIND INFRASTRUCTURE_CONSUMER_INSTANCE INFRASTRUCTURE_REF_NAME INFRASTRUCTURE_REF_KIND; do
                    if [[ $INFRASTRUCTURE_REF_NAME == $TEMPLATE_RESOURCE_INSTANCE && $INFRASTRUCTURE_REF_KIND == $TEMPLATE_RESOURCE ]]; then
                        echo -e "\n\t Found $TEMPLATE_RESOURCE/$TEMPLATE_RESOURCE_INSTANCE being referenced by $INFRASTRUCTURE_CONSUMER_KIND/$INFRASTRUCTURE_CONSUMER_INSTANCE."
                        could_be_removed="false"
                    fi
                    done < /tmp/template_resources_consumers.txt

                    # Check if there are currently any cloned template resources still linked to the template resource instance
                    EXISTING_CLONED_RESOURCES=$(kubectl -n "$TARGET_NAMESPACE" get $CLONED_TEMPLATE_RESOURCE -o jsonpath="{ $.items[?(@.metadata.annotations.cluster\.x-k8s\.io\/cloned-from-name == '$TEMPLATE_RESOURCE_INSTANCE')].metadata.name}" | wc -w)

                    # Don't consider template resource instance for deletion if cloned resources still exist for it
                    if [[ $EXISTING_CLONED_RESOURCES -gt 0 ]]; then
                        echo -e "\n\t The following $CLONED_TEMPLATE_RESOURCE resources are annotated with cluster.x-k8s.io/cloned-from-name=$TEMPLATE_RESOURCE_INSTANCE"
                        kubectl -n "$TARGET_NAMESPACE" get $CLONED_TEMPLATE_RESOURCE -o jsonpath="{ $.items[?(@.metadata.annotations.cluster\.x-k8s\.io\/cloned-from-name == '$TEMPLATE_RESOURCE_INSTANCE')].metadata.name}" | sed 's/^/\'$'\t/'
                        echo -e "\n\t Thus $TEMPLATE_RESOURCE/$TEMPLATE_RESOURCE_INSTANCE is not considered for garbage collection."
                        could_be_removed="false"
                    fi
                fi

                # Only for (Kubeadm|RKE2)ConfigTemplate resources
                if [[ $TEMPLATE_RESOURCE =~ .*ConfigTemplate ]]; then

                    # Check there's no MachineSet.spec.template.spec.bootstrap.configRef.name usage for the template resource instance
                    kubectl -n "$TARGET_NAMESPACE" get MachineSet -o=custom-columns=KIND:.kind,NAME:.metadata.name,BOOTSTRAP_CONFIG_REF_NAME:.spec.template.spec.bootstrap.configRef.name,BOOTSTRAP_CONFIG_REF_KIND:.spec.template.spec.bootstrap.configRef.kind --no-headers >> /tmp/template_resources_consumers.txt

                    # Check there's no MachineDeployment.spec.template.spec.bootstrap.configRef.name usage for the template resource instance
                    kubectl -n "$TARGET_NAMESPACE" get MachineDeployment -o=custom-columns=KIND:.kind,NAME:.metadata.name,BOOTSTRAP_CONFIG_REF_NAME:.spec.template.spec.bootstrap.configRef.name,BOOTSTRAP_CONFIG_REF_KIND:.spec.template.spec.bootstrap.configRef.kind --no-headers >> /tmp/template_resources_consumers.txt

                    while read BOOTSTRAP_CONSUMER_KIND BOOTSTRAP_CONSUMER_INSTANCE BOOTSTRAP_CONFIG_REF_NAME BOOTSTRAP_CONFIG_REF_KIND; do
                    if [[ $BOOTSTRAP_CONFIG_REF_NAME == $TEMPLATE_RESOURCE_INSTANCE && $BOOTSTRAP_CONFIG_REF_KIND == $TEMPLATE_RESOURCE ]]; then
                        echo -e "\n\t Found $TEMPLATE_RESOURCE/$TEMPLATE_RESOURCE_INSTANCE being referenced by $BOOTSTRAP_CONSUMER_KIND/$BOOTSTRAP_CONSUMER_INSTANCE."
                        could_be_removed="false"
                    fi
                    done < /tmp/template_resources_consumers.txt
                fi

                if [[ "$could_be_removed" == "true" ]]; then
                    echo -e "\n\t Deleting $TEMPLATE_RESOURCE/$TEMPLATE_RESOURCE_INSTANCE"
                    kubectl -n "$TARGET_NAMESPACE" delete "$TEMPLATE_RESOURCE/$TEMPLATE_RESOURCE_INSTANCE" | sed 's/^/\'$'\t/'
                fi
            done
        done
    fi
done
