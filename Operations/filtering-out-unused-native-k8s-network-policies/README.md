
# Kubernetes Network Policy Unused Endpoint Finder

This script is designed to list all native Kubernetes network policies that have zero endpoints attached to them. It is useful for identifying and potentially cleaning up unused policies in your Kubernetes cluster.

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
- Access to the Kubernetes cluster where you want to analyze the policies.

## Installation

1. **Python 3**

   Ensure Python 3 is installed on your system. The script uses Python 3 syntax and libraries. You can verify if Python 3 is installed and find its version by running:

   ```bash
   python3 --version
   ```

   If you don't have Python 3, you will need to install it. The installation method depends on your operating system. For example, on Ubuntu, you can install Python 3 by running:

   ```bash
   sudo apt-get update
   sudo apt-get install python3
   ```

2. **Pip for Python 3**

   Pip is the package installer for Python. You'll use it to install the Kubernetes Python client. You can check if pip for Python 3 is installed by running:

   ```bash
   pip3 --version
   ```

   If it's not installed, you can install it on Ubuntu with:

   ```bash
   sudo apt-get install python3-pip
   ```

3. **Kubernetes Python Client**

   The script uses the Kubernetes Python client to interact with your Kubernetes cluster. You can install it using pip:

   ```bash
   pip3 install kubernetes
   ```

4. **Kubernetes Configuration**

   The script uses your local Kubernetes configuration file (`~/.kube/config`) to connect to your cluster. Ensure you have kubectl installed and configured to communicate with your cluster. You can verify kubectl is correctly configured by running:

   ```bash
   kubectl get nodes
   ```

## Usage

1. **Create the Script**

   After having the pre-requisites sorted, create an executable script file:

   ```bash
   vi k8s-policy.py
   ```

   Save the file.

2. **Make the Script Executable**

   ```bash
   chmod +x k8s-policy.py
   ```

3. **Run the Script**

   ```bash
   ./k8s-policy.py
   ```

   The script will run and print all the policies with zero endpoints attached. It will also create a text file named `kubernetes-unused-policies.txt`, which you can save for further analysis or use as input to a cleanup script.

   Example output:

   ```text
   Kubernetes Policies with 0 endpoints attached are as below:
   Policy 'test-policy/allow-same-namespace' has no endpoints attached.
   The output has also been written to kubernetes-unused-policies.txt. Analyze it for further information.
   ```

   You can view the generated text file:

   ```bash
   cat kubernetes-unused-policies.txt
   ```

## Customization

- Modify the script as needed to adjust the output format or to integrate with additional tools or scripts in your environment.

## Troubleshooting

If you encounter any issues, please check the following:

- Ensure your Kubernetes cluster is running and accessible.
- Verify the paths to your configuration files.
- Check the Python script for any errors or exceptions.

## Contributing

We welcome contributions from the community! To contribute, follow these steps:

1. Fork this repository.
2. Create a new branch with a descriptive name.
3. Make your changes and commit them with clear messages.
4. Push your changes to your fork.
5. Submit a pull request with a detailed description of your changes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
