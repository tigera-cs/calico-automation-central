# AKS BYO CNI Cluster With Custom Networking

This repository provides a Terraform blueprint for deploying an Azure Kubernetes Service (AKS) cluster with a Bring Your Own (BYO) Container Network Interface (CNI) setup. It will spin up a Public AKS Cluster with No CNI installed.

## Overview

The BYO CNI setup gives users full control over the networking stack in an AKS cluster.

## Prerequisites

Ensure the following prerequisites are met before deploying the AKS cluster:

- **Azure Subscription**: Active subscription with necessary permissions.
- **Terraform**: Installed on your system. [Download Terraform](https://www.terraform.io/downloads.html)
- **Azure CLI**: Installed and authenticated. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **kubectl**: Installed for Kubernetes cluster management. [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Features

- **BYO CNI**: Customize the networking stack to meet specific requirements.
- **Calico Integration**: Leverage Calico for advanced network policies and enhanced networking capabilities.
- **Flexible Networking**: Support for hybrid networking configurations and policies tailored to workload needs.

## Deployment Steps

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/tigera-cs/calico-automation-central.git
   cd calico-automation-central/Installation/terraform-blueprints/aks-byo-cni-calico-networking
   ```

2. **Configure Azure Authentication**:

   Authenticate using Azure CLI:

   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

3. **Initialize Terraform**:

   Initialize the Terraform working directory:

   ```bash
   terraform init
   ```

4. **Modify Variables**:

   Review and update variables in the `variables.tf` file as necessary.

5. **Plan the Deployment**:

   Generate an execution plan:

   ```bash
   terraform plan
   ```

6. **Deploy the Resources**:

   Apply the Terraform configuration:

   ```bash
   terraform apply
   ```

   Confirm the action when prompted.

7. **Retrieve Kubernetes Credentials**:

   Fetch the Kubernetes configuration to interact with the AKS cluster:

   ```bash
   az aks get-credentials --resource-group <resource-group-name> --name <aks-cluster-name>
   ```

8. **Verify Deployment**:

   Verify the cluster status and the Calico setup:

   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## Cleanup

To destroy the deployed resources:

```bash
terraform destroy
```

Confirm the action when prompted.

## Additional Resources

- [Calico Documentation](https://docs.tigera.io)
- [Azure Kubernetes Service (AKS) Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform AKS Module](https://registry.terraform.io/modules/Azure/aks/azurerm/latest)
