# AKS Azure CNI Overlay Networking Terraform Blueprint

This repository provides a Terraform blueprint for deploying an Azure Kubernetes Service (AKS) cluster configured with Azure CNI Overlay networking and Calico for network policy enforcement.

## Overview

Azure CNI Overlay networking allows pods to receive IP addresses from a private CIDR, separate from the VNet hosting the nodes. This approach conserves IP addresses in the VNet and enables large-scale cluster deployments. Calico enhances this setup by providing robust network policy capabilities, allowing fine-grained control over pod communication.

## Prerequisites

Before deploying the AKS cluster using this blueprint, ensure you have the following:

- **Azure Subscription**: Active subscription with appropriate permissions.
- **Terraform**: Installed on your local machine. [Download Terraform](https://www.terraform.io/downloads.html)
- **Azure CLI**: Installed and authenticated. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Features

- **Azure CNI Overlay Networking**: Pods receive IPs from a private CIDR, conserving VNet IP space and supporting large-scale deployments. ([learn.microsoft.com](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay))
- **Calico Network Policies**: Implement fine-grained network policies for enhanced security and traffic management. ([docs.tigera.io](https://docs.tigera.io/calico-enterprise/latest/getting-started/install-on-clusters/aks))

## Customization

- **Node Pool Configuration**: Adjust VM sizes, node counts, and other parameters in the `variables.tf` file to suit your requirements.
- **Networking Settings**: Modify CIDR ranges, DNS settings, and other networking configurations as needed.

## Deployment Steps

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/tigera-cs/calico-automation-central.git
   cd calico-automation-central/Installation/terraform-blueprints/aks-azure-cni-overlay-networking
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

4. **Review and Modify Variables**:

   Review the `variables.tf` file and modify any default values as necessary.

5. **Plan the Deployment**:

   Generate and review the execution plan:

   ```bash
   terraform plan
   ```

6. **Apply the Deployment**:

   Apply the Terraform configuration to create the AKS cluster:

   ```bash
   terraform apply
   ```

   Confirm the apply action when prompted.

7. **Configure kubectl Access**:

   Retrieve the Kubernetes configuration to manage your AKS cluster:

   ```bash
   az aks get-credentials --resource-group <resource-group-name> --name <aks-cluster-name>
   ```

8. **Verify Deployment**:

   Check the status of the nodes and pods to ensure the cluster is operational:

   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   ```

## Cleanup

To remove all resources created by this deployment:

```bash
terraform destroy
```

Confirm the destroy action when prompted.

## Additional Resources

- [Azure CNI Overlay Networking in AKS](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
- [Calico on Azure Kubernetes Service](https://docs.tigera.io/calico/latest/getting-started/kubernetes/managed-public-cloud/aks)

---

*Note: Ensure that all variable values and configurations comply with your organization's policies and Azure subscription limits.*
