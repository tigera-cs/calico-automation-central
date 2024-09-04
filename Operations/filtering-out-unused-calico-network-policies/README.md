
# Calico Network Policies Analyzer

![Calico Logo](/images/logo/Tigera-Logo-Transparent.png)

This script allows you to list all Calico network policies that have 0 endpoints attached to them. It helps you identify unused policies, making it easier to clean up your network configurations.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Output](#output)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Requirements

Ensure you have the following tools installed:

- [Python 3](https://www.python.org/downloads/)
- [Pip for Python 3](https://pip.pypa.io/en/stable/installation/)
- [Kubernetes Python Client](https://pypi.org/project/kubernetes/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [calicoctl](https://docs.tigera.io/calico/latest/getting-started/calicoctl/)
- [calicoq](https://docs.tigera.io/calico/latest/getting-started/calicoq/)
- kube-config file with access to the cluster where you want to analyze the policies.

> **Note:** Ensure that the `calicoctl` and `calicoq` binaries match the Calico Enterprise version installed on the cluster. You can check the Calico Enterprise version by running `kubectl describe` on the calico-node pods and looking for the image version of the calico-node container. If the binaries do not match, you can use the `--allow-version-mismatch` flag to make it work.

## Installation

### 1. Python 3
Ensure Python 3 is installed on your system. You can verify if Python 3 is installed by running:

```bash
python3 --version
```

If you don't have Python 3, install it using the following commands on Ubuntu:

```bash
sudo apt-get update
sudo apt-get install python3
```

### 2. Pip for Python 3
Pip is the package installer for Python. Verify if pip for Python 3 is installed by running:

```bash
pip3 --version
```

If it's not installed, you can install it on Ubuntu with:

```bash
sudo apt-get install python3-pip
```

### 3. Kubernetes Python Client
Install the Kubernetes Python client using pip:

```bash
pip3 install kubernetes
```

### 4. Kubernetes Configuration
Ensure you have `kubectl` installed and configured to communicate with your Kubernetes cluster. Verify the configuration by running:

```bash
kubectl get nodes
```

## Usage

1. SSH into a node in your Kubernetes cluster.
2. Run the script:

```bash
python3 calico_unused_policies_analyzer.py
```

This will generate two output files in the same directory:

- `calico-unused-policy.txt` (contains the list of all Calico network policies with 0 endpoints)
- `kubernetes-unused-policies.txt` (contains the list of all Kubernetes network policies with 0 endpoints)

> **Note:** The script ignores policies in the `allow-tigera` tiers that have 0 endpoints attached to them, as they are managed by the Tigera operator and should not be deleted.

## Output

The script creates the following output files:

- `calico-unused-policy.txt`: A list of all Calico network policies with 0 endpoints attached.
- `kubernetes-unused-policies.txt`: A list of all Kubernetes network policies with 0 endpoints attached.

## Customization

You can customize the script as needed, such as modifying the tiers or namespaces to include or exclude specific policies. Ensure any changes align with your network security requirements.

## Troubleshooting

If you encounter any issues, check the following:

- Ensure your Kubernetes cluster is running and accessible.
- Verify the paths to your configuration files and binaries (`calicoctl`, `calicoq`).
- Confirm that the versions of `calicoctl` and `calicoq` match your Calico Enterprise installation, or use the `--allow-version-mismatch` flag.
- Check the script output for any errors or warnings.

## Contributing

We welcome contributions from the community! To contribute, follow these steps:

1. Fork this repository.
2. Create a new branch with a descriptive name.
3. Make your changes and commit them with clear messages.
4. Push your changes to your fork.
5. Submit a pull request with a detailed description of your changes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
