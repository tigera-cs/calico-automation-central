#!/bin/bash

kubectl delete crd installers.operator.calicocloud.io

kubectl delete -n calico-cloud deployments calico-cloud-controller-manager

kubectl delete secrets -n calico-cloud api-key

kubectl delete clusterrole calico-cloud-installer-role calico-cloud-installer-tigera-operator-role calico-cloud-installer-sa-creator-role

kubectl delete clusterrolebinding calico-cloud-installer-crb

kubectl delete role -n calico-cloud calico-cloud-installer-ns-role
kubectl delete role -n kube-system calico-cloud-installer-kube-system-role
kubectl delete role -n tigera-prometheus calico-cloud-installer-tigera-prometheus-role
kubectl delete role -n tigera-image-assurance calico-cloud-installer-tigera-image-assurance-role
kubectl delete role -n calico-system calico-cloud-installer-calico-system-role
kubectl delete role -n tigera-risk-system calico-cloud-installer-tigera-risk-system-role
kubectl delete role -n tigera-runtime-security calico-cloud-installer-tigera-runtime-security-role
kubectl delete rolebinding -n calico-cloud calico-cloud-installer-ns-rbac
kubectl delete rolebinding -n kube-system calico-cloud-installer-kube-system-rbac
kubectl delete rolebinding -n tigera-operator calico-cloud-installer-tigera-operator-rbac
kubectl delete rolebinding -n tigera-operator-cloud calico-cloud-installer-tigera-operator-rbac
kubectl delete rolebinding -n tigera-prometheus calico-cloud-installer-tigera-prometheus-rbac
kubectl delete rolebinding -n tigera-image-assurance calico-cloud-installer-tigera-image-assurance-rbac
kubectl delete rolebinding -n tigera-license calico-cloud-installer-tigera-license-rbac
kubectl delete rolebinding -n tigera-access calico-cloud-installer-tigera-access-rbac
kubectl delete rolebinding -n calico-system calico-cloud-installer-calico-system-rbac
kubectl delete rolebinding -n tigera-risk-system calico-cloud-installer-tigera-risk-system-rbac
kubectl delete rolebinding -n tigera-runtime-security calico-cloud-installer-tigera-runtime-security-rbac

# This disconnects the cluster from the Calico Cloud service.
# This is done so that then the Managed Cluster can be deleted in the UI.
kubectl delete managementclusterconnection tigera-secure
