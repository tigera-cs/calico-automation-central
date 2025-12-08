#!/bin/bash
# set -xv
######################################################################################################################################
## EKS Cluster mesh setup in Overlay on Calico Enterprise 
#
# In this lab we will be using Calico CNI and Calico VXLAN/overlay cluster mesh. Cluster mesh is able to 
# federate clusters over a VXLAN overlay network setup between the participating clusters with minimal VPC/underlay configuration needed. 
# There is no need to advertise pod and service CIDRs to the underlay/VPC network with this mode.
# Usage:    
#           Script will take the unique name prefix as an argument and use it to build the clusters name, run:
#          ./deploy-cluster3-eks-on-ce.sh <unique name>
#
# Example: 
#         ./deploy-cluster3-eks-on-ce.sh mktest1
#          This will create the 3rd cluster with the names: 
#                 mktest1-ce-eks-mcm3  (region -> us-west-1)
#
# NOTE: Change the VPC cidr values under the variables section
#       Make sure to have a unique VPC cidrs, better to modify them to avoid conflicts.          
#######################################################################################################################################

uniqname=$1

## Step 1 - Set Variables
# Set local environement variables
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="${BASE_DIR}/cent-mcm-overlay"
MCM_DIR="$OVERLAY_DIR"
MANF_DIR="${MCM_DIR}/manifests"
DEMO_DIR="${OVERLAY_DIR}/demo-apps"

pull_secret="${BASE_DIR}/config.json"
lic_file="${BASE_DIR}/license.yaml"

# Set Clusters Variables
echo "## Step 1 - Set Clusters Variables"
#uniqname="chgme"
CLUSTER1_NAME=${uniqname}-ce-eks-mcm1
CLUSTER2_NAME=${uniqname}-ce-eks-mcm2
CLUSTER1_REGION=ca-central-1
CLUSTER2_REGION=us-west-1
EKS_VERSION=1.33
NODE_TYPE="t3.large"
CLUSTERS_COMMON_NAME=${uniqname}-ce-eks-mcm
CLUSTER1_VPC_CIDR=192.163.0.0/24
CLUSTER2_VPC_CIDR=10.5.0.0/24
CLUSTER1_VPC_ADDR=${CLUSTER1_VPC_CIDR%%/*}
CLUSTER2_VPC_ADDR=${CLUSTER2_VPC_CIDR%%/*}
CLUSTER1_VPC_ADDR_SPACE="${CLUSTER1_VPC_CIDR%/24}/16"
CLUSTER2_VPC_ADDR_SPACE="${CLUSTER2_VPC_CIDR%/24}/16"

CLUSTER3_NAME=${uniqname}-ce-eks-mcm3
CLUSTER3_REGION=us-west-1
CLUSTER3_VPC_CIDR=172.30.0.0/24
CLUSTER3_VPC_ADDR=${CLUSTER3_VPC_CIDR%%/*}
CLUSTER3_VPC_ADDR_SPACE="${CLUSTER3_VPC_CIDR%/24}/16"
CLUSTER3_SVC_CIDR=172.22.0.0/16
CLUSTER3_SVC_ADDR=${CLUSTER3_SVC_CIDR%%/*}
CLUSTER3_POD_CIDR=172.18.0.0/16
CLUSTER3_POD_ADDR=${CLUSTER3_POD_CIDR%%/*}

## Step 2 - Get aws profile
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

# Get the kube-config contexts
echo ""
echo "Get the kube-config contexts:"
kubectl config get-contexts
username="$USER"

##################################################
## Module 2 - Deploy the EKS Clusters
##################################################
echo ""
echo "=============================================="
echo "### Module 2 - Deploy the EKS Cluster"
echo "=============================================="
echo ""
## Step 1 - Check available availability zones for the regions you plan to build clusters in
echo "## Step 1 - Check available availability zones"
aws ec2 describe-availability-zones --region $CLUSTER3_REGION --query '*[].ZoneName' --output table

echo "## Step 3 - set availability zones for CLUSTER-3"

indx=0
for az in $(aws ec2 describe-availability-zones --region $CLUSTER3_REGION --query '*[].ZoneName' --output text); do
  if [[ $indx == 0 ]]; then 
    CLUSTER3_AZ_LIST="\"$az\""
  else
    CLUSTER3_AZ_LIST="$CLUSTER3_AZ_LIST,\"$az\""
  fi 
  ((indx++))
done;


## Step 4 - Cluster-3 initial setup with eksctl
echo ""
echo "##--- Step 4 -  Cluster-3 initial setup with eksctl"

# Change the values under cent-mcm-overlay/manifests/eksctl-config-cluster3.yaml as needed
cp ${MANF_DIR}/eksctl-config-cluster2.yaml ${MANF_DIR}/eksctl-config-cluster3-custom.yaml
sed -i '' "s/172.21.0.0/${CLUSTER3_SVC_ADDR}/g" ${MANF_DIR}/eksctl-config-cluster3-custom.yaml
sed -i '' "s/10.10.0.0/${CLUSTER3_VPC_ADDR}/g" ${MANF_DIR}/eksctl-config-cluster3-custom.yaml
sed -e "s/\${CLUSTER_NAME}/${CLUSTER3_NAME}/g" -e "s/\${CLUSTER_REGION}/${CLUSTER3_REGION}/g" -e "s/\${EKS_VERSION}/${EKS_VERSION}/g" -e "s/\${CLUSTER_AZS}/${CLUSTER3_AZ_LIST}/g" ${MANF_DIR}/eksctl-config-cluster3-custom.yaml | eksctl create cluster -f-

rc=$?
if [[ $rc -ne 0 ]]; then
   echo "ERROR: eksctl failed with exit code $rc" >&2
   exit 1
fi   

echo ""
echo ""

# switch your context for cluster-3 (i.e us-west-1)
# Sample: kubectl config use-context meysam@mk-ce-eks-mcm2.us-east-1.eksctl.io
# kubectl config use-context ${username}@${CLUSTER2_NAME}.${CLUSTER2_REGION}.eksctl.io

TARGET_CTX="${username}@${CLUSTER3_NAME}.${CLUSTER3_REGION}.eksctl.io"
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
echo ""
echo " ##--- Step 1 - Verify the health of Management cluster (cluster-1)" 
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

echo ""
echo "----------------------------------------"
echo "# Check all the components are running ($ kubctl  get tigerastatuses.operator.tigera.io)"
echo "----------------------------------------"
${BASE_DIR}/chk_tigeracomponents_mgmt.sh


#########################################
### Cluster-3 Installation Steps
#########################################
echo ""
echo "---------------------------------------------------------------------"
echo "=== $(date +'%Y-%m-%d %H:%M:%S') - Cluster-3 Installation started ==="
echo "---------------------------------------------------------------------"
echo ""
# switch your context for cluster-3 (us-west-1)
TARGET_CTX="${username}@${CLUSTER3_NAME}.${CLUSTER3_REGION}.eksctl.io"
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
echo "##--- Step 2 - Install Tigera crds, operator & prometheus" 
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
cp ${MANF_DIR}/managedcluster-custom-resources-example.yaml ${MANF_DIR}/managedcluster-custom-resources-cluster-3.yaml
sed -i '' "s/172.17.0.0/${CLUSTER3_POD_ADDR}/g" ${MANF_DIR}/managedcluster-custom-resources-cluster-3.yaml
kubectl create -f ${MANF_DIR}/managedcluster-custom-resources-cluster-3.yaml
sleep 30

## STEP 3 - Add worker nodes to the cluster
# Add worker nodes to the cluster using the values for the clustername and region as used from the eksctl-config-cluster-2.yaml file
echo "## STEP 3 - Add worker nodes to the cluster-3"
eksctl create nodegroup --cluster $CLUSTER3_NAME --region $CLUSTER3_REGION --node-type $NODE_TYPE --max-pods-per-node 100 --nodes 2 --nodes-max 3 --nodes-min 2
sleep 20

# Check kubectl get nodes shows the nodes as available
${BASE_DIR}/wait_for_nodes.sh
echo ""

# Wait until Tigera API Server is Available
${BASE_DIR}/wait_for_apiserver.sh
echo ""

echo ""
echo "----------------------------------------"
echo "# STEP 4 -  Create the Managed cluster connection"
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
export MANAGED_CLUSTER=${CLUSTERS_COMMON_NAME}-managed-cluster-3
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
# switch your context to cluster-3 (us-east-1)

TARGET_CTX="${username}@${CLUSTER3_NAME}.${CLUSTER3_REGION}.eksctl.io"
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


# or *Optionally do it from UI
#Connect cluster - Manager UI
#In the Manager UI left navbar, click Managed Clusters.

#On the Managed Clusters page, click the button, Add Cluster.

#Name your cluster that is easily recognized in a list of managed clusters, and click Create Cluster.

#Download the manifest.
#apply thee manifest  

# Wait until all component come up shows a status of Available=True
${BASE_DIR}/chk_tigeracomponents_mngd.sh

# define admin-level permissions for the service account (mcm-user) (run on managed cluster cluster-2):
kubectl create clusterrolebinding mcm-user-admin --serviceaccount=default:mcm-user --clusterrole=tigera-network-admin




##################################################
# Module 4 - Setup VPC Peering
##################################################
echo "=============================================="
echo "# Module 4 - Setup VPC Peering"
echo "=============================================="
echo ""
echo "AWS credentials loaded for profile: $AWS_PROFILE"
echo ""


echo "-----------------------------------------------"
# Get the VPC IDs using the EKS cluster names:
echo "# Get the VPC IDs:"
CLUSTER_A_VPC=$(aws ec2 describe-vpcs --region $CLUSTER1_REGION --filters Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values="$CLUSTER1_NAME" --query "Vpcs[*].VpcId" --output text)
echo $CLUSTER_A_VPC

CLUSTER_C_VPC=$(aws ec2 describe-vpcs --region $CLUSTER3_REGION --filters Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values="$CLUSTER3_NAME" --query "Vpcs[*].VpcId" --output text)
echo $CLUSTER_C_VPC

echo "-----------------------------------------------"
# Generate VPC peering request
echo ""
echo "# Generate VPC peering request"
aws ec2 create-vpc-peering-connection --region $CLUSTER1_REGION --vpc-id $CLUSTER_A_VPC --peer-vpc-id $CLUSTER_C_VPC --peer-region $CLUSTER3_REGION --tag-specifications "ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=${uniqname}-mcm1-to-mcm3}]" 2>&1 > /dev/null

echo "-----------------------------------------------"
# Get the route table id for each cluster
echo "Route table ids:"
ROUTE_ID_CA=$(aws ec2 describe-route-tables --region $CLUSTER1_REGION --filters "Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values=$CLUSTER1_NAME" "Name=tag:"aws:cloudformation:logical-id",Values="PublicRouteTable"" --query "RouteTables[*].RouteTableId" --output text)
echo $ROUTE_ID_CA

ROUTE_ID_CC=$(aws ec2 describe-route-tables --region $CLUSTER3_REGION --filters "Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values=$CLUSTER3_NAME" "Name=tag:"aws:cloudformation:logical-id",Values="PublicRouteTable"" --query "RouteTables[*].RouteTableId" --output text)
echo $ROUTE_ID_CC

echo "-----------------------------------------------"
# Get the peering id
#PEER_ID=$(aws ec2 describe-vpc-peering-connections --region $CLUSTER1_REGION --query "VpcPeeringConnections[0].VpcPeeringConnectionId" --output text)

PEER_ID=$(aws ec2 describe-vpc-peering-connections \
  --region "$CLUSTER1_REGION" \
  --filters "Name=tag:Name,Values=${uniqname}-mcm1-to-mcm3" \
  --query 'VpcPeeringConnections[0].VpcPeeringConnectionId' \
  --output text)

echo "Peering ID: $PEER_ID"

echo "-- Waiting for resource become available ...."
sleep 10

echo "-----------------------------------------------"
# Approve the peering request
echo "Approving peering request...."
#aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PEER_ID  --region $CLUSTER2_REGION --no-cli-pager 2>&1
AWS_PAGER="" aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id "$PEER_ID" \
  --region "$CLUSTER3_REGION" \
  --no-cli-pager \
  2>&1

echo "-- Waiting for resource become available ...."
sleep 10

echo "-----------------------------------------------"
# Add the required routes to the route table for each VPC to its peer VPC CIDR as defined in the eksctl config file
echo " Adding routes to the route table for each VPC..."
aws ec2 create-route --region $CLUSTER1_REGION --route-table-id $ROUTE_ID_CA --destination-cidr-block $CLUSTER3_VPC_CIDR --vpc-peering-connection-id $PEER_ID
aws ec2 create-route --region $CLUSTER3_REGION --route-table-id $ROUTE_ID_CC --destination-cidr-block $CLUSTER1_VPC_CIDR --vpc-peering-connection-id $PEER_ID


echo "-----------------------------------------------"
## Setup Security Groups and disable interface source-destination check
# Ensure that as a minimum VXLAN UDP port 4789 is opened on both clusters for each other's VPC CIDR, and possibly ICMP
echo " Adding VXLAN UDP port 4789 to both clusters security groups"

echo "-----------------------------------------------"
# get security group for both CLUSTER1_NAME & CLUSTER2_NAME
SG1_ID=$(aws ec2 describe-instances --region $CLUSTER1_REGION --filters "Name=tag:Name,Values=*$CLUSTER1_NAME*" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[*].NetworkInterfaces[0].Groups[0].GroupId' --output text)

SG3_ID=$(aws ec2 describe-instances --region $CLUSTER3_REGION --filters "Name=tag:Name,Values=*$CLUSTER3_NAME*" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[*].NetworkInterfaces[0].Groups[0].GroupId' --output text)

echo "-----------------------------------------------"
# allow UDP traffic over port 4789 for CLUSTER1_NAME and CLUSTER2_NAME
aws ec2 authorize-security-group-ingress --region $CLUSTER1_REGION --group-id $SG1_ID --protocol udp --port 4789 --cidr $CLUSTER3_VPC_ADDR_SPACE 2>&1
aws ec2 authorize-security-group-ingress --region $CLUSTER3_REGION --group-id $SG3_ID --protocol udp --port 4789 --cidr $CLUSTER1_VPC_ADDR_SPACE 2>&1

echo "------------------!!! ATTENTION !!!-----------------------------"
echo "# Ensure that source-destination check is disabled in the interfaces of all of the worker nodes,"
echo "# so that traffic originating from a peered VPC subnet is not dropped by the receiving node interface in a local VPC."
echo "# do it from the aws console on all workers on both clusters..."
echo "follow this link -> https://docs.aws.amazon.com/vpc/latest/userguide/work-with-nat-instances.html#EIP_Disable_SrcDestCheck "

echo "Waiting for 3 minutes..."
sleep 180

echo "-----------------------------------------------"
# switch your context for cluster-1 (ca-central-1)
TARGET_CTX="${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io"
echo "Switching to context: $TARGET_CTX"
kubectl config use-context "$TARGET_CTX" > /dev/null 2>&1

echo "-----------------------------------------------"
# Wait until your ECK cluster is back up and running.
"${BASE_DIR}/chk_tigeracomponents_mgmt.sh"

echo "-----------------------------------------------"
# Wait until tigera-elasticsearch health show green
kubectl get -n tigera-elasticsearch elastic

echo ""
echo "======================== VPC Peering cluster-3 COMPLETED =========================="



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

# List your contexts (replace with your actual names)
username="$USER"
CL1_CTX=${username}@${CLUSTER1_NAME}.${CLUSTER1_REGION}.eksctl.io
CL2_CTX=${username}@${CLUSTER2_NAME}.${CLUSTER2_REGION}.eksctl.io
CL3_CTX=${username}@${CLUSTER3_NAME}.${CLUSTER2_REGION}.eksctl.io

kubectl config view --raw --minify --flatten --context="${CL1_CTX}" > ~/kubeconfigs/${CLUSTER1_NAME}.config
kubectl config view --raw --minify --flatten --context="${CL2_CTX}" > ~/kubeconfigs/${CLUSTER2_NAME}.config
kubectl config view --raw --minify --flatten --context="${CL3_CTX}" > ~/kubeconfigs/${CLUSTER3_NAME}.config

echo " Contexts names:"
echo " 1) cluster-1: ${CL1_CTX} "
echo " 2) cluster-2: ${CL2_CTX} "
echo " 3) cluster-2: ${CL3_CTX} "
echo "... Saved in ~/kubeconfigs:"
ls -lrt ~/kubeconfigs/${uniqname}*

echo ""
echo "# use commands below to set your contexts in each terminals:"
echo "cluster-1: export KUBECONFIG=~/kubeconfigs/${CLUSTER1_NAME}.config "
echo "cluster-2: export KUBECONFIG=~/kubeconfigs/${CLUSTER2_NAME}.config "
echo "cluster-3: export KUBECONFIG=~/kubeconfigs/${CLUSTER3_NAME}.config "
echo ""
echo "--------------------------------------------"
echo "$(date +'%Y-%m-%d %H:%M:%S') - Script ended"
echo "--------------------------------------------"
echo "All Done                                    "
echo "Congradulations you added a 3rd Managed cluster" 
echo "--------------------------------------------"
