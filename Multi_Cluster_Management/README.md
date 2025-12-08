# Calico Enterprise Multi-Cluster Management Installation

## Overview
This folder contains end-to-end automation to deploy **Calico Enterprise Multi-Cluster Management (MCM)** on Amazon EKS clusters.

The automation is built on top of the public reference repository:  
https://github.com/tigera-solutions/cent-mcm-overlay

This Multi Cluster Management deployment is an automated scripts to achieve building Management cluster and Managd clusters which it is based on the public github rep tigera-solutions/cent-mcm-overlay (Refer to link in the reference).
In this EKS-focused scenario, you will implement Multi Cluster Management on Calico Enterprise and then later you can implement Calico Cluster Mesh in VXLAN/overlay mode using a dedicated script in order to achieve federated services and policy federation across clusters. Then, In oder to create the cluster mesh, you will be using the provided script according the "Module 5 - Setup VXLAN Cluster Mesh" of the public github repo tigera-solutions/cent-mcm-overlay.

# What the Script Does:
This set of scripts automates the following workflow:
Note: An optional third managed cluster can be deployed by passing `3` as an argument to the main script.

| Script                                      | Description                                                                 |
|---------------------------------------------|-----------------------------------------------------------------------------|
| `1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh` | Main orchestration script – deploys 2 or 3 EKS clusters with MCM           |
| `4_vpc-peering.sh`                          | Establishes VPC peering connections and routes between all cluster VPCs (It's called inside the main script)    |
| `chk_tigeracomponents_mgmt.sh`              | Verifies all required Tigera components are running on the Management cluster |
| `chk_tigeracomponents_mngd.sh`              | Verifies all required Tigera components are running on Managed cluster(s)  |
| `deploy-cluster3-eks-on-ce.sh`              | (Optional) Deploys a third managed EKS cluster and onboards it to MCM      |
| `wait_for_apiserver.sh`                     | Helper – waits for Calico API server to reach available=True state        |
| `wait_for_nodes.sh`                         | Helper – waits for all worker nodes to reach Ready state                   |

## Prerequisites

### Cluster & Networking Requirements
- At least **two EKS clusters** in **different AWS regions** with Calico Enterprise already installed as the CNI.
- **Unique CIDRs** across clusters:
  - VPC / Node subnet CIDRs (no overlap)
  - Pod CIDRs
  - Service CIDRs
- VPC peering between all cluster VPCs (script `4_vpc-peering.sh` automates this).

- Pull Secret
  
  Ensure that the Docker config JSON file is placed correctly at base directory "config.json" (or tweak the script accoridngly). This file is required for pulling Calico Enterprise images.

- License File
  Place your Calico Enterprise license file at base directory (or tweak the script accoridngly).

### Tools Required
- AWS account with sufficient permissions
- `awscli` (v2 recommended)
- `eksctl` (latest)
- `kubectl` configured for EKS
- `git`
- `ncat` (netcat)

Follow the official tool installation guide here:  
https://github.com/tigera-solutions/cent-mcm-overlay/blob/main/modules/module-1-getting-started.md

## Usage

- Clone this repository to your local machine: 
```bash
git clone https://github.com/tigera-cs/calico-automation-central/tree/main/Multi_Cluster_Management.git
cd CE-Cluster-Mesh-EKS
```
- Review and adjust variables in the main script(s), VPC cidr values under the variables section,                                                                           "
   to ensure to have a unique VPC cidrs, better to modify them to avoid conflicts.
   Set your own desired variable for:
  - Region
  - Vpc cidr

  modify them in all three scripts 
  - 1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh
  - 4_vpc-peering.sh
  - deploy-cluster3-eks-on-ce.sh

  And script will take care of the rest. 
  The serviceCidr(s) are predefined for all three clusters, with the following values in the respective order:
   172.20.0.0/16,
   172.21.0.0/16,
   172.22.0.0/16,
  And no need to change them. 

- Execute the main orchestration script:

#### Syntax: For 2 clusters (1 management + 1 managed)
```bash
./1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh -u <unique-prefix-name> -m 2
```
#### Syntax: For 3 clusters (1 management + 2 managed)
```bash
./1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh -u <unique-prefix-name> -m 3
```


#### Examples:
-   For 2 clusters
```bash
   ./1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh -u mktest1 -m 2
   This will create two clusters with the names: 
        mktest1-ce-eks-mcm1  (region -> ca-central-1)
        mktest1-ce-eks-mcm2  (region -> us-west-1)
```
-   For 3 clusters
```bash
   ./1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh -u mktest1 -m 3
    This will create three clusters with the names: 
        mktest1-ce-eks-mcm1  (region -> ca-central-1)
        mktest1-ce-eks-mcm2  (region -> us-west-1)
        mktest1-ce-eks-mcm3  (region -> us-west-1)
```

### VPC Peering 
In case you do not want the script does the VPC peering for you, comment out the line 761 in the main script 1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh
```bash
# VPC peering 
"${BASE_DIR}/4_vpc-peering.sh" "$uniqname" || { echo "VPC Peering failed!"; exit 1; }
```
### Help
Run the script help for instant help:
```bash
   ./1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh --help
```

This will:
- Reads the variables, customize the manifest/eksctl-config-cluster1.yaml and manifest/eksctl-config-cluster2.yamlfiles, updates the vpc.Cidr according to your defined values.
- Deployes EKS clusters in different regions.
- Create a AWS Kubernetes storage class for EBS.
- Installs Calico Enterprise standard method.
- Set up the necessary namespaces and secrets for Calico Enterprise.
- Apply the Tigera operator and Prometheus operator manifests.
- Configure the installation of Calico Enterprise with custom resources and license.
- Configure the Management cluster resources.
- Configure the Managed cluster and connect it to Management cluster.
- In case you decided to deploy the 3rd cluster (meaning the 2nd managed cluster) , a 3rd service Cidr and podCidr are also gets customized and saved in file manifest/eksctl-config-cluster3.yaml and manifest/managedcluster-custom-resources-cluster-3.yaml 
- Creates VPC peering.
- Finally, reports the calico components health, elasticseach.
- Reports the service loadbalancer URL link to access the Manager UI. 
- Reports all cluster contexts and save them in the user home dir under ~/kubeconfigs/
  
### deployment duration: 
- 2 x clusters 40 mins
- 3 x clusters 50-55 mins
  
###  Access your Manager UI console:
- Script saves the mcm-user's ui token in a file named ui_tokens in the base directory. The first token is for the Manager UI and the second token is for Kibana user "elastic"   

### Manage your clusters (CLI)
Script saves all cluster contexts in the user home dir under ~/kubeconfigs/
and reports the usage commands to to set your contexts in each terminals. Example below:

```bash
# Extract your contexts
 Contexts names:
 1) cluster-1: meysam@mk01-ce-eks-mcm1.ca-central-1.eksctl.io
 2) cluster-2: meysam@mk01-ce-eks-mcm2.us-west-1.eksctl.io
 3) cluster-2: meysam@mk01-ce-eks-mcm3.us-west-1.eksctl.io
... Saved in ~/kubeconfigs:
-rw-r--r--@ 1 meysam  staff  2415 Dec  1 15:02 /Users/meysam/kubeconfigs/mk01-ce-eks-mcm1.config
-rw-r--r--@ 1 meysam  staff  2391 Dec  1 15:02 /Users/meysam/kubeconfigs/mk01-ce-eks-mcm2.config
-rw-r--r--@ 1 meysam  staff  2391 Dec  1 15:02 /Users/meysam/kubeconfigs/mk01-ce-eks-mcm3.config

# use commands below to set your contexts in each terminals:
cluster-1: export KUBECONFIG=~/kubeconfigs/mk01-ce-eks-mcm1.config
cluster-2: export KUBECONFIG=~/kubeconfigs/mk01-ce-eks-mcm2.config
cluster-3: export KUBECONFIG=~/kubeconfigs/mk01-ce-eks-mcm3.config
````

## Setup VXLAN Cluster Mesh
- To setup the cluster mesh, from here, follow this [VXLAN Cluster Mesh](https://github.com/tigera-solutions/cent-mcm-overlay/blob/main/modules/module-5-setup-clustermesh.md)

## Clean up
- work-in-progress

# References

Public reference lab (basis for this automation):
https://github.com/tigera-solutions/cent-mcm-overlay

Module 5 – Setup VXLAN Cluster Mesh:
https://github.com/tigera-solutions/cent-mcm-overlay/blob/main/modules/module-5-vxlan-cluster-mesh.md