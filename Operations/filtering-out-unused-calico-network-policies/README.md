# Unused Calico Network Policies Script

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

Automate the installation of Calico Enterprise on Kubernetes clusters using Terraform. This repository provides all necessary resources and configurations to set up Calico Enterprise, including the EBS CSI driver, storage classes, namespaces, secrets, and custom resources.

This script identifies Calico network policies and Kubernetes network policies with zero endpoints attached. It helps in cleaning up unused policies to maintain a tidy and efficient network configuration.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Requirements

Ensure you have the following tools installed:

- [Python 3](https://www.python.org/downloads/)
- [pip for Python 3](https://pip.pypa.io/en/stable/installation/)
- [Kubernetes Python Client](https://pypi.org/project/kubernetes/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [calicoctl](https://docs.tigera.io/calico/latest/getting-started/calicoctl/)
- [calicoq](https://docs.tigera.io/calico/latest/getting-started/calicoq/)
- [Have a working kubectl binary installed]
- [Access to the cluster where we want to analyze the policies]

## Installation

Clone this repository to your local machine:

```bash
git clone https://github.com/your-username/calico-enterprise-terraform.git
cd calico-enterprise-terraform

```

## Usage

- Initialize Terraform:
```bash 
  terraform init
```
- Review and apply the Terraform plan:
```bash 
  terraform plan
  terraform apply
```

This will:
- Install Helm if it is not already installed.
- Add the Helm repository for the EBS CSI driver and install the driver.
- Create a Kubernetes storage class for EBS.
- Set up the necessary namespaces and secrets for Calico Enterprise.
- Apply the Tigera operator and Prometheus operator manifests.
- Configure the installation of Calico Enterprise with custom resources and license.

## Customization

Configuration Files
- Kubernetes Config Path: Ensure that your ~/.kube/config file points to the correct Kubernetes cluster.

Custom Resources
- Modify the custom resource definitions to customize the Calico Enterprise installation. For example, change the IP pool CIDR or other network configurations in the calico_installation_configuration resource.

Pull Secret
- Ensure that the Docker config JSON file is placed correctly at /home/tigera/config.json (or tweak the script accoridngly). This file is required for pulling Calico Enterprise images.

License File
- Place your Calico Enterprise license file at /home/tigera/license.yaml ((or tweak the script accoridngly)).

## Troubleshooting

If you encounter any issues, please check the following:

- Ensure your Kubernetes cluster is running and accessible.
- Verify the paths to your configuration files and secrets.
- Check the Terraform logs for any errors during execution.
- For further assistance, feel free to open an issue in this repository.


## Contributing

We welcome contributions from the community! To contribute, follow these steps:

- Fork this repository.
- Create a new branch with a descriptive name.
- Make your changes and commit them with clear messages.
- Push your changes to your fork.
- Submit a pull request with a detailed description of your changes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.



