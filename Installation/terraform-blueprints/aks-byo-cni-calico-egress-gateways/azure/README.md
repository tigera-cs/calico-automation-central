# AKS BYO CNI with Calico Egress Gateways Terraform Blueprint

This repository provides a Terraform blueprint for deploying an Azure Kubernetes Service (AKS) cluster with a Bring Your Own (BYO) Container Network Interface (CNI) setup. It integrates Calico for advanced network policy capabilities and implements egress gateways for controlled outbound traffic.

## Overview

The BYO CNI setup allows users to customize their networking stack within an AKS cluster. Combined with Calico, this setup enables fine-grained network policy enforcement and control over egress traffic using egress gateways.

## Prerequisites

Ensure the following prerequisites are met before deploying the AKS cluster:

- **Azure Subscription**: Active subscription with necessary permissions.
- **Terraform**: Installed on your system. [Download Terraform](https://www.terraform.io/downloads.html)
- **Azure CLI**: Installed and authenticated. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **kubectl**: Installed for Kubernetes cluster management. [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

##  Features

- BYO CNI: Customize the networking stack to meet specific requirements.
- Calico Integration: Leverage Calico for advanced network policies and secure egress traffic control.
-	Egress Gateways: Control outbound traffic from specific workloads for compliance and enhanced security.

### Deploy

To provision this example:

```sh
terraform init
terraform apply
```

Enter `yes` at command prompt to apply

### Validate

1. Authenticate to Azure.

```sh
az login
```

2. Update the kubeconfig

```sh
az aks get-credentials --name <SPOKE1 CLUSTER_NAME> --resource-group <SPOKE RESOURCE GROUP>
```

4. View the pods that were created:

```sh
kubectl get pods -A

# Output should show some pods running
```

5. View the nodes that were created:

```sh
kubectl get nodes

# Output should show some nodes running
```

### Destroy

To teardown and remove the resources created in this example:

```sh
terraform destroy --auto-approve
```

## Additional Resources
- [Calico Documentation](https://docs.tigera.io/)
- [Azure Kubernetes Service (AKS) Documentation](https://learn.microsoft.com/en-us/azure/aks/)
- [Terraform AKS Module](https://registry.terraform.io/modules/Azure/aks/azurerm/latest)
