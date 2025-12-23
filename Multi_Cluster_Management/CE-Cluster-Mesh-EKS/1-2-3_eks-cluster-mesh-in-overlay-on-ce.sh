#!/bin/bash
# set -xv

# Function to display help guide
function mcm_deploy_help() {
        printf '\n%.0s' {1..2}
        echo "##########################################################################################################################################"
        echo "## EKS Cluster mesh setup in Overlay on Calico Enterprise                                                                                 "
        echo "#                                                                                                                                         "
        echo "# In this lab we will be using Calico CNI and Calico VXLAN/overlay cluster mesh. Cluster mesh is able to                                  "
        echo "# federate clusters over a VXLAN overlay network setup between the participating clusters with minimal VPC/underlay configuration needed. "
        echo "# There is no need to advertise pod and service CIDRs to the underlay/VPC network with this mode.                                         "
        echo "# Usage:                                                                                                                                  "
        echo "#           Script takes the unique name prefix as an argument and use it to build the clusters name.                                     "
        echo "#           it also takes the number of clusters for the MCM deployment, run:                                                             "
        echo "#            $0 -u <unique-name> -m <members-number>                                                                                      "
        echo "#           or                                                                                                                            "
        echo "#            $0 --uniqname <unique-name> --members <members-number>                                                                       "
        echo "#                                                                                                                                         "
        echo "#                                                                                                                                         "
        echo "# Mandatory:                                                                                                                              "
        echo "#          uniqname: A unique name (string)                                                                                               "
        echo "#          members:  Number of participant clusters (integer: 2 or 3)                                                                     "
        echo "# Example:                                                                                                                                "
        echo "#         1)                                                                                                                              "
        echo "#         ./1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh -u mktest1 -m 2                                                                    "
        echo "#          This will create two clusters with the names:                                                                                  "
        echo "#                 mktest1-ce-eks-mcm1  (region -> ca-central-1)                                                                           "
        echo "#                 mktest1-ce-eks-mcm2  (region -> us-east-1)                                                                              "
        echo "#         2)                                                                                                                              "
        echo "#         ./1-2-3_eks-cluster-mesh-in-overlay-on-ce.sh -u mktest1 -m 3                                                                    "
        echo "#          This will create three clusters with the names:                                                                                "
        echo "#                 mktest1-ce-eks-mcm1  (region -> ca-central-1)                                                                           "
        echo "#                 mktest1-ce-eks-mcm2  (region -> us-west-1)                                                                              "
        echo "#                 mktest1-ce-eks-mcm3  (region -> us-west-1)                                                                              "
        echo "#                                                                                                                                         "
        echo "# NOTE: Change the VPC cidr values under the variables section,                                                                           "
        echo "#       to ensure to have a unique VPC cidrs, better to modify them to avoid conflicts.                                                   "
        echo "##########################################################################################################################################"

        printf '\n%.0s' {1..2}
        exit
}


if [ -z "$1" ]
then
   mcm_deploy_help
fi

set -euo pipefail

## === VALIDATION FUNCTIONS ===
# Function to verify if the input values are integer number
is_num() {
    [[ "$1" =~ ^[0-9]+$ ]] && echo "$1" || echo "-1"
}

# Validate uniqname: letters, digits, - and _ only
# Must start/end with alphanumeric, no consecutive -- or __
validate_uniqname() {
    local name="$1"
    [[ -z "$name" ]] && return 1
    if [[ "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]$ ]] && \
       [[ ! "$name" =~ --|__ ]]; then
        echo "$name"
        return 0
    else
        return 1
    fi
}


# === Portable argument parsing (works on macOS + Linux) ===
UNIQNAME=""
MEM=""

# Manual parsing loop
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--uniqname)
            if [[ -z "$2" || "$2" =~ ^- ]]; then
                echo "ERROR: --uniqname requires an argument" >&2
                exit 1
            fi
            UNIQNAME="$2"
            shift 2
            ;;
        -m|--members)
            if [[ -z "$2" || "$2" =~ ^- ]]; then
                echo "ERROR: --members requires an argument" >&2
                exit 1
            fi
            MEM="$2"
            shift 2
            ;;
        --help)
                echo "Usage: $0 -u|--uniqname <uniqname> -m|--members <2|3>"
                echo ""
                echo "  <uniqname>  : alphanumeric + -_ (must start/end with letter/digit)"
                echo "  <members>   : 2 or 3 only"
                exit 0
            ;;
        -h)
                echo "Usage: $0 -u|--uniqname <uniqname> -m|--members <2|3>"
                echo ""
                echo "  <uniqname>  : alphanumeric + -_ (must start/end with letter/digit)"
                echo "  <members>   : 2 or 3 only"
                exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            echo "Use --help for usage" >&2
            exit 1
            ;;
    esac
done

# Call to validate the provided input.
# === Validation after parsing ===
if [[ -z "$UNIQNAME" ]]; then
    echo "ERROR: --uniqname is required!" >&2
    echo "Use --help for usage" >&2
    exit 1
fi

# Validate uniqname format
if ! validated=$(validate_uniqname "$UNIQNAME"); then
    echo "ERROR: Invalid uniqname: '$UNIQNAME'" >&2
    echo "   Must contain only letters, numbers, -, _" >&2
    echo "   Must start and end with a letter or number" >&2
    echo "   No consecutive -- or __ allowed" >&2
    exit 1
fi
UNIQNAME="$validated"

# Validate members
if ! MEM=$(is_num "$MEM") || [[ "$MEM" -lt 2 || "$MEM" -gt 3 ]]; then
    echo "ERROR: --members must be 2 or 3 (you gave: '$MEM')" >&2
    exit 1
fi


echo "All good! Proceeding with:"
echo "   UNIQNAME = $UNIQNAME"
echo "   Members  = $MEM"

uniqname=$UNIQNAME
num_mem=$MEM
#uniqname=$1

##################################################
## Module 1 - Getting started
##################################################
echo "=============================================="
echo "### Module 1 - Getting started"
echo "=============================================="
echo "=== $(date +'%Y-%m-%d %H:%M:%S') - Script started ==="

# Step 1 - Local Environment Setup

# Ensure your environment has these tools
# 1) AWS CLI upgrade to v2 - link for installation: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# 2) eksctl                - link for installation: https://docs.aws.amazon.com/eks/latest/userguide/setting-up.html
# 3) kubectl               - link for installation: https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html#macos_kubectl
# 4) git and Ncat          - link for installation: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

# autocompletion for kubectl.
#for macOS:
#    https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/#enable-shell-autocompletion
#     for linux:
#    https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion

# For linux:       
#echo 'source <(kubectl completion bash)' >>~/.bashrc
#echo 'alias k=kubectl' >>~/.bashrc
#echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
#source ~/.bashrc

# For MacOS:

#brew install bash-completion@2
#echo 'source <(kubectl completion bash)' >>~/.bash_profile
#sudo mkdir /opt/homebrew/etc/bash_completion.d
#sudo kubectl completion bash > /opt/homebrew/etc/bash_completion.d/kubectl
#echo 'source /opt/homebrew/etc/bash_completion.d/kubectl' >> ~/.bash_profile
#echo 'alias k=kubectl' >>~/.bash_profile
#echo 'complete -o default -F __start_kubectl k' >>~/.bash_profile
#source ~/.bash_profile

# Set local environemtn variables
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="${BASE_DIR}/cent-mcm-overlay"
MCM_DIR="$OVERLAY_DIR"
MANF_DIR="${MCM_DIR}/manifests"
DEMO_DIR="${OVERLAY_DIR}/demo-apps"

pull_secret="${BASE_DIR}/config.json"
lic_file="${BASE_DIR}/license.yaml"

# Clone the repo (only if not already there) ===
REPO_URL="https://github.com/tigera-solutions/cent-mcm-overlay.git"  # CHANGE THIS AS REQUIRED


# Step 2 - Get aws profile
# AUTOMATICALLY LOAD AWS CREDENTIALS FROM ~/.aws/credentials ===
AWS_PROFILE="${AWS_PROFILE:-default}"  # Change profile name if not 'default'

# Parse credentials file
CRED_FILE="$HOME/.aws/credentials"

if [[ ! -f "$CRED_FILE" ]]; then
  echo "Error: AWS credentials file not found at $CRED_FILE"
  exit 1
fi

# Extract Access Key and Secret Key for the profile
export AWS_ACCESS_KEY_ID=$(grep -A 2 "\[${AWS_PROFILE}\]" "$CRED_FILE" | grep aws_access_key_id | awk '{print $3}')
export AWS_SECRET_ACCESS_KEY=$(grep -A 2 "\[${AWS_PROFILE}\]" "$CRED_FILE" | grep aws_secret_access_key | awk '{print $3}')

# Optional: Validate
if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "Error: Could not find credentials for profile '$AWS_PROFILE' in $CRED_FILE"
  exit 1
fi

echo "AWS credentials loaded for profile: $AWS_PROFILE"

rm -rf $OVERLAY_DIR

# Step 3 - Clone the git repo
git clone $REPO_URL

echo "# check the content of cent-mcm-overlay directory"
ls -l $MCM_DIR

##################################################
## Module 2 - Deploy the EKS Clusters
##################################################
echo ""
echo "=============================================="
echo "### Module 2 - Deploy the EKS Clusters"
echo "=============================================="
echo "=== $(date +'%Y-%m-%d %H:%M:%S') - started ==="

## Step 1 - Set Variables
# note: Set the CLUSTER1_NAME are desire and probabely better to modify them to avoid conflicts

#uniqname="chgme"
CLUSTER1_NAME=${uniqname}-ce-eks-mcm1
CLUSTER2_NAME=${uniqname}-ce-eks-mcm2
CLUSTER1_REGION=ca-central-1
CLUSTER2_REGION=us-west-1
EKS_VERSION=1.33
NODE_TYPE="t3.large"
CLUSTERS_COMMON_NAME=${uniqname}-ce-eks-mcm
CLUSTER1_VPC_CIDR=192.164.0.0/24
CLUSTER2_VPC_CIDR=10.6.0.0/24
CLUSTER1_VPC_ADDR=${CLUSTER1_VPC_CIDR%%/*}
CLUSTER2_VPC_ADDR=${CLUSTER2_VPC_CIDR%%/*}
CLUSTER1_VPC_ADDR_SPACE="${CLUSTER1_VPC_CIDR%/24}/16"
CLUSTER2_VPC_ADDR_SPACE="${CLUSTER2_VPC_CIDR%/24}/16"

## Step 2 - Check available availability zones for the regions you plan to build clusters in
aws ec2 describe-availability-zones --region $CLUSTER1_REGION --query '*[].ZoneName' --output table
aws ec2 describe-availability-zones --region $CLUSTER2_REGION --query '*[].ZoneName' --output table

## Step 3 -  Set availability zones for each cluster
# set availability zones for CLUSTER1

indx=0
for az in $(aws ec2 describe-availability-zones --region $CLUSTER1_REGION --query '*[].ZoneName' --output text); do
  if [[ $indx == 0 ]]; then 
    CLUSTER1_AZ_LIST="\"$az\""
  else
    CLUSTER1_AZ_LIST="$CLUSTER1_AZ_LIST,\"$az\""
  fi 
  ((indx++))
done;

# set availability zones for CLUSTER2
# NOTE: us-east-1e AZ does not support creating EKS control plane in it. It is better to avoid setting that AZ in EKS cluster configuration when creating the cluster.

indx=0
CLUSTER2_AZ_ARR=($(aws ec2 describe-availability-zones --region $CLUSTER2_REGION --query '*[].ZoneName' --output text))
# use only first 4 AZs from the array
for az in ${CLUSTER2_AZ_ARR[@]:0:4}; do
  if [[ $indx == 0 ]]; then 
    CLUSTER2_AZ_LIST="\"$az\""
  else
    CLUSTER2_AZ_LIST="$CLUSTER2_AZ_LIST,\"$az\""
  fi 
  ((indx++))
done;


## Step 4 - Cluster-1 initial setup with eksctl
echo ""
echo "##--- Step 4 -  Cluster-1 initial setup with eksctl"

# Change the values under cent-mcm-overlay/manifests/eksctl-config-cluster1.yaml as needed
cp ${MANF_DIR}/eksctl-config-cluster1.yaml ${MANF_DIR}/eksctl-config-cluster1-custom.yaml
sed -i '' "s/192.168.0.0/${CLUSTER1_VPC_ADDR}/g" ${MANF_DIR}/eksctl-config-cluster1-custom.yaml
sed -e "s/\${CLUSTER_NAME}/${CLUSTER1_NAME}/g" -e "s/\${CLUSTER_REGION}/${CLUSTER1_REGION}/g" -e "s/\${EKS_VERSION}/${EKS_VERSION}/g" -e "s/\${CLUSTER_AZS}/${CLUSTER1_AZ_LIST}/g" ${MANF_DIR}/eksctl-config-cluster1-custom.yaml | eksctl create cluster -f-

rc=$?
if [[ $rc -ne 0 ]]; then
   echo "ERROR: eksctl failed with exit code $rc" >&2
   exit 1
fi   

# Get the kube-config contexts
echo ""
echo "Get the kube-config contexts:"
kubectl config get-contexts
username="$USER"

echo ""
echo ""
# switch your context for cluster-1 (ca-central-1)
# Sample: kubectl config use-context meysam@mk-ce-eks-mcm1.ca-central-1.eksctl.io
# kubectl config use-context ${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io

TARGET_CTX="${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"
kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1

# verify
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "ERROR")

if [[ "$CURRENT_CTX" == "$TARGET_CTX" ]]; then
    echo "Context verified: $CURRENT_CTX"
else
    echo "ERROR: Failed to switch context!"
    echo "  Expected: $TARGET_CTX"
    echo "  Got     : $CURRENT_CTX"
    exit 1
fi

echo "Running on correct cluster: $CURRENT_CTX"
echo " Proceeding to next step...."
echo ""

# check if aws-node daemonset is deployed, and if so, delete it
AWS_NODE_DS=$(kubectl get daemonset -n kube-system aws-node -o jsonpath='{.metadata.name}' 2>/dev/null || echo "")

if [[ -n "$AWS_NODE_DS" ]]; then
  echo "Found: aws-node DaemonSet exists. Deleting..."
  kubectl delete daemonset -n kube-system aws-node
else
  echo "aws-node DaemonSet does NOT exist. Skipping."
fi


## Step 5 - Cluster-2 initial setup with eksctl
echo ""
echo "##--- Step 5 -  Cluster-2 initial setup with eksctl"

# Change the values under cent-mcm-overlay/manifests/eksctl-config-cluster2.yaml as needed
cp ${MANF_DIR}/eksctl-config-cluster2.yaml ${MANF_DIR}/eksctl-config-cluster2-custom.yaml
sed -i '' "s/10.10.0.0/${CLUSTER2_VPC_ADDR}/g" ${MANF_DIR}/eksctl-config-cluster2-custom.yaml
sed -e "s/\${CLUSTER_NAME}/${CLUSTER2_NAME}/g" -e "s/\${CLUSTER_REGION}/${CLUSTER2_REGION}/g" -e "s/\${EKS_VERSION}/${EKS_VERSION}/g" -e "s/\${CLUSTER_AZS}/${CLUSTER2_AZ_LIST}/g" ${MANF_DIR}/eksctl-config-cluster2-custom.yaml | eksctl create cluster -f-

rc=$?
if [[ $rc -ne 0 ]]; then
   echo "ERROR: eksctl failed with exit code $rc" >&2
   exit 1
fi   

echo ""
echo ""

# switch your context for cluster-2 (us-east-1)
# Sample: kubectl config use-context meysam@mk-ce-eks-mcm2.us-east-1.eksctl.io
# kubectl config use-context ${username}@${CLUSTER2_NAME}.${CLUSTER2_REGION}.eksctl.io

TARGET_CTX="${username}@${CLUSTER2_NAME}.${CLUSTER2_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"

kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1
# verify
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "ERROR")

if [[ "$CURRENT_CTX" == "$TARGET_CTX" ]]; then
    echo "Context verified: $CURRENT_CTX"
else
    echo "ERROR: Failed to switch context!"
    echo "  Expected: $TARGET_CTX"
    echo "  Got     : $CURRENT_CTX"
    exit 1
fi

echo "Running on correct cluster: $CURRENT_CTX"
echo " Proceeding to next step...."
echo ""

echo "# check if aws-node daemonset is deployed, and if so, delete it"
AWS_NODE_DS=$(kubectl get daemonset -n kube-system aws-node -o jsonpath='{.metadata.name}' 2>/dev/null || echo "")

if [[ -n "$AWS_NODE_DS" ]]; then
  echo "Found: aws-node DaemonSet exists. Deleting..."
  kubectl delete daemonset -n kube-system aws-node
else
  echo "aws-node DaemonSet does NOT exist. Skipping."
fi





##################################################
# Module 3.1 - Install Calico Enterprise
##################################################
echo ""
echo "=============================================="
echo "### Module 3.1 - Install Calico Enterprise"
echo "=============================================="
echo "=== $(date +'%Y-%m-%d %H:%M:%S') - started ==="
#
## Cluster-1 will act as the Management cluster and we will enable MCM with cluster-2 being added as a managed cluster.
#
#########################################
### Step 1 - Cluster-1 Installation Steps
#########################################
echo ""
echo "---------------------------------------------------------------------"
echo "=== $(date +'%Y-%m-%d %H:%M:%S') - Cluster-1 Installation started ==="
echo "---------------------------------------------------------------------"
echo ""
# switch your context for cluster-1 (ca-central-1)
TARGET_CTX="${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"
kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1

# verify
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "ERROR")

if [[ "$CURRENT_CTX" == "$TARGET_CTX" ]]; then
    echo "Context verified: $CURRENT_CTX"
else
    echo "ERROR: Failed to switch context!"
    echo "  Expected: $TARGET_CTX"
    echo "  Got     : $CURRENT_CTX"
    exit 1
fi

echo "Running on correct cluster: $CURRENT_CTX"
echo " Proceeding to next step...."
echo ""

# Install Tigera crds, operator & prometheus
echo "# Install Tigera crds, operator & prometheus" 
kubectl create -f https://downloads.tigera.io/ee/v3.21.2/manifests/operator-crds.yaml
kubectl create -f https://downloads.tigera.io/ee/v3.21.2/manifests/tigera-operator.yaml

kubectl create -f https://downloads.tigera.io/ee/v3.21.2/manifests/tigera-prometheus-operator.yaml

echo "#--- Install the pull secret:"
kubectl create secret generic tigera-pull-secret --type=kubernetes.io/dockerconfigjson -n tigera-operator --from-file=.dockerconfigjson=${pull_secret}

# Install Tigera custom resources
# Modify the mgmtcluster-custom-resources-example.yaml file as needed and apply it.
kubectl create -f ${MANF_DIR}/mgmtcluster-custom-resources-example.yaml

## Step 2 - For LogStorage , install the EBS CSI driver
# Extract Access Key and Secret Key for the profile
export AWS_ACCESS_KEY_ID=$(grep -A 2 "\[${AWS_PROFILE}\]" "$CRED_FILE" | grep aws_access_key_id | awk '{print $3}')
export AWS_SECRET_ACCESS_KEY=$(grep -A 2 "\[${AWS_PROFILE}\]" "$CRED_FILE" | grep aws_secret_access_key | awk '{print $3}')

kubectl create secret generic aws-secret --namespace kube-system --from-literal "key_id=${AWS_ACCESS_KEY_ID}" --from-literal "access_key=${AWS_SECRET_ACCESS_KEY}"

echo "#--- # Install the CSI driver:"
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.39"

echo "#--- Install Storage Class"
# Apply the storage class:
kubectl apply -f - <<-EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: tigera-elasticsearch
provisioner: ebs.csi.aws.com
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
EOF


## Step 3 - Add worker nodes to the cluster
echo "----------------------------------------"
echo "##--- Step 3 - Add worker nodes to cluster-1"
echo "----------------------------------------"
eksctl create nodegroup --cluster $CLUSTER1_NAME --region $CLUSTER1_REGION --node-type $NODE_TYPE --max-pods-per-node 100 --nodes 2 --nodes-max 3 --nodes-min 2

## Step 4 - Verify 
echo "----------------------------------------"
echo "##--- Step 4 - Verify"
echo "----------------------------------------"
# Check kubectl get nodes shows the nodes as available
"${BASE_DIR}/wait_for_nodes.sh"
echo ""

# Wait until Tigera API Server is Available
"${BASE_DIR}/wait_for_apiserver.sh"
echo ""

# Install the Tigera license file.
kubectl apply -f ${lic_file}

# Wait until all component come up shows a status of Available=True
"${BASE_DIR}/chk_tigeracomponents_mgmt.sh"

echo "----------------------------------------"
echo "##--- Step 5 - Create a LoadBalancer service for the tigera-manager pods  to access from your machine:"
echo "----------------------------------------"
kubectl create -f ${MANF_DIR}/mgmt-cluster-lb.yaml
sleep 10
echo "# Management UI accessile via svc/tigera-manager-external: "
echo "          https://$(kubectl -n tigera-manager get svc tigera-manager-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

echo ""
echo "----------------------------------------"
echo "##--- Step 6 - setup access CE Manager UI"
echo "----------------------------------------"
# create a sa and rolebinding:
echo " create ServiceAccount ..."
kubectl create sa mcm-user
kubectl create clusterrolebinding mcm-user-admin --clusterrole=tigera-network-admin --serviceaccount=default:mcm-user 

# create token for sa using secret:
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: mcm-user
  annotations:
    kubernetes.io/service-account.name: "mcm-user"
EOF

# get the SA token:
echo "Saving UI tokens to file ${BASE_DIR}/ui_tokens"
kubectl get secret mcm-user -o go-template='{{.data.token | base64decode}}'  > ${BASE_DIR}/ui_tokens
echo "" >> ${BASE_DIR}/ui_tokens

# decode the Kibana password
echo "----------------------------------------"
echo "--------------"
echo "Kibana username: elastic "
echo "Kibana pass:"  
kubectl -n tigera-elasticsearch get secret tigera-secure-es-elastic-user -o go-template='{{.data.elastic | base64decode}}' && echo
kubectl -n tigera-elasticsearch get secret tigera-secure-es-elastic-user -o go-template='{{.data.elastic | base64decode}}' >> ${BASE_DIR}//ui_tokens
echo "" >> ${BASE_DIR}/ui_tokens
echo "--------------"
echo "----------------------------------------"

echo ""
echo "----------------------------------------"
echo "##--- Step 7 - Create the mgmt cluster resources"
echo "----------------------------------------"  
# Create another LoadBalancer svc to expose the MCM targetport of 9449 and using that for the managed cluster to access. yaml is at manifests/mcm-svc-lb.yaml:

kubectl create -f ${MANF_DIR}/mcm-svc-lb.yaml
sleep 20

# export MGMT_ADDR_MCM=<address-of-mcm-svc>:<port>
MCM_NLB_DNS=$(kubectl -n tigera-manager get svc tigera-manager-mcm -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export MGMT_ADDR_MCM=${MCM_NLB_DNS}:9449

# Apply the ManagementCluster CR
kubectl apply -f - <<-EOF
apiVersion: operator.tigera.io/v1
kind: ManagementCluster
metadata:
  name: tigera-secure
spec:
  address: $MGMT_ADDR_MCM
  tls:
    secretName: tigera-management-cluster-connection
EOF

echo ""
echo "Management Cluster Address is:      ${MGMT_ADDR_MCM}"

# STEP 8 - Ensure that the tigera-manager and tigera-linseed pods restart

kubectl -n tigera-manager rollout restart deployment tigera-manager
sleep 3
kubectl -n tigera-elasticsearch rollout restart deployment tigera-linseed

echo ""
echo "----------------------------------------"
echo "# STEP 8 - Check all the components are running ($ kubctl  get tigerastatuses.operator.tigera.io)"
echo "----------------------------------------"
"${BASE_DIR}/chk_tigeracomponents_mgmt.sh"


#########################################
### Step 9 - Cluster-2 Installation Steps
#########################################
echo ""
echo "---------------------------------------------------------------------"
echo "=== $(date +'%Y-%m-%d %H:%M:%S') - Cluster-2 Installation started ==="
echo "---------------------------------------------------------------------"
echo ""
# switch your context for cluster-2 (us-east-1)
TARGET_CTX="${username}@${CLUSTER2_NAME}.${CLUSTER2_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"
kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1

# verify
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "ERROR")

if [[ "$CURRENT_CTX" == "$TARGET_CTX" ]]; then
    echo "Context verified: $CURRENT_CTX"
else
    echo "ERROR: Failed to switch context!"
    echo "  Expected: $TARGET_CTX"
    echo "  Got     : $CURRENT_CTX"
    exit 1
fi

echo "Running on correct cluster: $CURRENT_CTX"
echo " Proceeding to next step...."
echo ""

# Install Tigera crds, operator & prometheus
echo "#--- Install Tigera crds, operator & prometheus" 
kubectl create -f https://downloads.tigera.io/ee/v3.21.2/manifests/operator-crds.yaml
kubectl create -f https://downloads.tigera.io/ee/v3.21.2/manifests/tigera-operator.yaml

kubectl create -f https://downloads.tigera.io/ee/v3.21.2/manifests/tigera-prometheus-operator.yaml

echo ""
# Install the pull secret:
echo "#--- Install the pull secret:"
kubectl create secret generic tigera-pull-secret --type=kubernetes.io/dockerconfigjson -n tigera-operator --from-file=.dockerconfigjson=${pull_secret}

# Install Tigera custom resources
# Modify the managedcluster-custom-resources-example.yaml file as needed and apply it. 
# In this case cluster-2 will be added to cluster-1 as a managed cluster so we omit all necessary components in the resources file, but ensure pod cidr is unique.
kubectl create -f ${MANF_DIR}/managedcluster-custom-resources-example.yaml
sleep 30

## STEP 10 - Add worker nodes to the cluster
# Add worker nodes to the cluster using the values for the clustername and region as used from the eksctl-config-cluster-2.yaml file
echo "## STEP 10 - Add worker nodes to the cluster-2"
eksctl create nodegroup --cluster $CLUSTER2_NAME --region $CLUSTER2_REGION --node-type $NODE_TYPE --max-pods-per-node 100 --nodes 2 --nodes-max 3 --nodes-min 2
sleep 20

# Check kubectl get nodes shows the nodes as available
"${BASE_DIR}/wait_for_nodes.sh"
echo ""

# Wait until Tigera API Server is Available
"${BASE_DIR}/wait_for_apiserver.sh"
echo ""

echo ""
echo "----------------------------------------"
echo "# STEP 11 -  Create the Managed cluster connection"
echo "----------------------------------------"
echo ""
# switch your context to cluster-1 (ca-central-1)
TARGET_CTX="${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"
kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1

# verify
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "ERROR")

if [[ "$CURRENT_CTX" == "$TARGET_CTX" ]]; then
    echo "Context verified: $CURRENT_CTX"
else
    echo "ERROR: Failed to switch context!"
    echo "  Expected: $TARGET_CTX"
    echo "  Got     : $CURRENT_CTX"
    exit 1
fi

echo "Running on correct cluster: $CURRENT_CTX"
echo " Proceeding to next step...."
echo ""

## connect-cluster---kubectl
# Choose a name for your managed cluster (run on mgmt cluster cluster-1):
echo " Running on the management cluster... creating ManagementClusterConnection resources:"
export MANAGED_CLUSTER=${CLUSTERS_COMMON_NAME}-managed-cluster-2
export MANAGED_CLUSTER_OPERATOR_NS=tigera-operator

# Add a managed cluster and save the manifest (run on mgmt cluster cluster-1):
kubectl -o jsonpath="{.spec.installationManifest}" > $MANAGED_CLUSTER.yaml create -f - <<EOF
apiVersion: projectcalico.org/v3
kind: ManagedCluster
metadata:
  name: $MANAGED_CLUSTER
spec:
  operatorNamespace: $MANAGED_CLUSTER_OPERATOR_NS
EOF

echo "Resource created and saved in file ${MANAGED_CLUSTER}.yaml "

# uncomment and Fix the managementClusterAddr - adding manually as there is a bug in above command, intermitanetly it does not incl managementClusterAddr
#MCM_NLB_DNS=$(kubectl -n tigera-manager get svc tigera-manager-mcm -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
#sed -i '' "/managementClusterAddr:/c\\
#  managementClusterAddr: \"${MCM_NLB_DNS}:9449\"" $MANAGED_CLUSTER.yaml

echo ""
echo ""
# Apply the connection manifest that you modified in the step, Add a managed cluster to the management cluster (run on managed cluster cluster-2):
# switch your context to cluster-2 (us-east-1)

TARGET_CTX="${username}@${CLUSTER2_NAME}.${CLUSTER2_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"
kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1

# verify
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || echo "ERROR")

if [[ "$CURRENT_CTX" == "$TARGET_CTX" ]]; then
    echo "Context verified: $CURRENT_CTX"
else
    echo "ERROR: Failed to switch context!"
    echo "  Expected: $TARGET_CTX"
    echo "  Got     : $CURRENT_CTX"
    exit 1
fi

echo "Running on correct cluster: $CURRENT_CTX"
echo " Proceeding to next step...."
echo ""
echo "----------------------------------------"
echo "---Connect the Managed cluster---"
echo "on Managed cluster, below resources:  "
echo "----------------------------------------"

kubectl apply -f $MANAGED_CLUSTER.yaml

echo "----------------------------------------"

# or *Optionally do it from UI
#Connect cluster - Manager UI
#In the Manager UI left navbar, click Managed Clusters.

#On the Managed Clusters page, click the button, Add Cluster.

#Name your cluster that is easily recognized in a list of managed clusters, and click Create Cluster.

#Download the manifest.
#apply thee manifest  

# Wait until all component come up shows a status of Available=True
"${BASE_DIR}/chk_tigeracomponents_mngd.sh"
echo ""

# define admin-level permissions for the service account (mcm-user) (run on managed cluster cluster-2):
kubectl create clusterrolebinding mcm-user-admin --serviceaccount=default:mcm-user --clusterrole=tigera-network-admin


# VPC peering 
"${BASE_DIR}/4_vpc-peering.sh" "$uniqname" || { echo "VPC Peering failed!"; exit 1; }
echo ""
echo ""

# Deploy cluster-3 (optional) 
echo "Checking the requested number of MCM cluster members."
if [[ "$num_mem" -eq 3 ]]; then
    echo "Requested cluster members is: $num_mem"
    echo "=== Proceeding to ... deploy the 3rd cluster ==="
    "${BASE_DIR}/deploy-cluster3-eks-on-ce.sh" "$uniqname" || {
        echo "ERROR: deploy-cluster3-eks-on-ce.sh failed!" >&2
        exit 1
    }
    echo "=== All 3 clusters have been deployed successfully ==="
    echo "Deployment complete — exiting."
    exit 0
else
    echo "Requested cluster members is: $num_mem"
    echo ""
fi

echo "=== The MCM deployed with two cluster memebrs successfully ==="
echo ""
echo "Proceeding to final step..."


## Report
echo ""
echo "------------------------------------------"
echo "------------------------------------------"
echo "How to onnect to Management cluster UI: "
echo ""
TARGET_CTX="${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"
kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1

# export MGMT_ADDR_MCM=<address-of-mcm-svc>:<port>
UI_NLB_DNS=$(kubectl -n tigera-manager get svc tigera-manager-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export MGMT_ADDR_UI=${UI_NLB_DNS}

echo " Management cluster UI is accessible at the address:   https://${MGMT_ADDR_UI} " 
echo ""
echo "EKS clusters and Calico Enterprise installation completed on two clusters"
echo "------------------------------------------"
echo "------------------------------------------"
echo ""
echo "# Extract your contexts"

# Create directory
mkdir -p ~/kubeconfigs

# Backup original 
cp ~/.kube/config ~/.kube/config.backup.$(date +%s)

# 3. List your contexts (replace with your actual names)
username="$USER"
CL1_CTX=${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io
CL2_CTX=${username}@${CLUSTER2_NAME}.${CLUSTER2_REGION}.eksctl.io
kubectl config view --raw --minify --flatten --context="${CL1_CTX}" > ~/kubeconfigs/${CLUSTER1_NAME}.config
kubectl config view --raw --minify --flatten --context="${CL2_CTX}" > ~/kubeconfigs/${CLUSTER2_NAME}.config

echo " Contexts names:"
echo " 1) cluster-1: ${CL1_CTX} "
echo " 2) cluster-2: ${CL2_CTX} "
echo "... Saved in ~/kubeconfigs:"
ls -lrt ~/kubeconfigs/${uniqname}*

echo ""
echo "# use commands below to set your contexts in each terminals:"
echo "cluster-1: export KUBECONFIG=~/kubeconfigs/${CLUSTER1_NAME}.config "
echo "cluster-2: export KUBECONFIG=~/kubeconfigs/${CLUSTER2_NAME}.config "
echo ""
echo "--------------------------------------------"
echo "$(date +'%Y-%m-%d %H:%M:%S') - Script ended"
echo "--------------------------------------------"
echo "All Done"
echo "--------------------------------------------"


