#!/bin/bash
# set -xv
set -euo pipefail

######################################################################################################################################
# Usage:
#           Script will take the unique name prefix as an argument  run:
#          ./04_vpc-peering.sh <unique name>
#
# Example:
#         ./04_vpc-peering.sh mktest1
#######################################################################################################################################

##################################################
# Module 4 - Setup VPC Peering
##################################################
echo "=============================================="
echo "# Module 4 - Setup VPC Peering"
echo "=============================================="
## // Under construction //
# note: Set the CLUSTER1_NAME are desire and probabely better to modify them to avoid conflicts
uniqname=$1

## Step 1 - Set Variables

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

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="${BASE_DIR}/cent-mcm-overlay"
MCM_DIR="$OVERLAY_DIR"
MANF_DIR="${MCM_DIR}/manifests"
DEMO_DIR="${OVERLAY_DIR}/demo-apps"

username="$USER"

# Step 2 - Get aws profile
# === AUTOMATICALLY LOAD AWS CREDENTIALS FROM ~/.aws/credentials ===
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

echo ""
echo "AWS credentials loaded for profile: $AWS_PROFILE"
echo ""


echo "-----------------------------------------------"
# Get the VPC IDs using the EKS cluster names:
echo "# Get the VPC IDs:"
CLUSTER_A_VPC=$(aws ec2 describe-vpcs --region $CLUSTER1_REGION --filters Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values="$CLUSTER1_NAME" --query "Vpcs[*].VpcId" --output text)
echo $CLUSTER_A_VPC

CLUSTER_B_VPC=$(aws ec2 describe-vpcs --region $CLUSTER2_REGION --filters Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values="$CLUSTER2_NAME" --query "Vpcs[*].VpcId" --output text)
echo $CLUSTER_B_VPC

echo "-----------------------------------------------"
# Generate VPC peering request
echo ""
echo "# Generate VPC peering request"
aws ec2 create-vpc-peering-connection --region $CLUSTER1_REGION --vpc-id $CLUSTER_A_VPC --peer-vpc-id $CLUSTER_B_VPC --peer-region $CLUSTER2_REGION --tag-specifications "ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=${uniqname}-mcm1-to-mcm2}]" 2>&1 > /dev/null

echo "-----------------------------------------------"
# Get the route table id for each cluster
echo "Route table ids:"
ROUTE_ID_CA=$(aws ec2 describe-route-tables --region $CLUSTER1_REGION --filters "Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values=$CLUSTER1_NAME" "Name=tag:"aws:cloudformation:logical-id",Values="PublicRouteTable"" --query "RouteTables[*].RouteTableId" --output text)
echo $ROUTE_ID_CA

ROUTE_ID_CB=$(aws ec2 describe-route-tables --region $CLUSTER2_REGION --filters "Name=tag:eksctl.cluster.k8s.io/v1alpha1/cluster-name,Values=$CLUSTER2_NAME" "Name=tag:"aws:cloudformation:logical-id",Values="PublicRouteTable"" --query "RouteTables[*].RouteTableId" --output text)
echo $ROUTE_ID_CB

echo "-----------------------------------------------"
# Get the peering id
#PEER_ID=$(aws ec2 describe-vpc-peering-connections --region $CLUSTER1_REGION --query "VpcPeeringConnections[0].VpcPeeringConnectionId" --output text)

PEER_ID=$(aws ec2 describe-vpc-peering-connections \
  --region "$CLUSTER1_REGION" \
  --filters "Name=tag:Name,Values=${uniqname}-mcm1-to-mcm2" \
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
  --region "$CLUSTER2_REGION" \
  --no-cli-pager \
  2>&1

echo ""
echo "-- Waiting for resource become available ...."
sleep 10

echo "-----------------------------------------------"
# Add the required routes to the route table for each VPC to its peer VPC CIDR as defined in the eksctl config file
echo " Adding routes to the route table for each VPC..."
aws ec2 create-route --region $CLUSTER1_REGION --route-table-id $ROUTE_ID_CA --destination-cidr-block $CLUSTER2_VPC_CIDR --vpc-peering-connection-id $PEER_ID
aws ec2 create-route --region $CLUSTER2_REGION --route-table-id $ROUTE_ID_CB --destination-cidr-block $CLUSTER1_VPC_CIDR --vpc-peering-connection-id $PEER_ID


echo "-----------------------------------------------"
## Setup Security Groups and disable interface source-destination check
# Ensure that as a minimum VXLAN UDP port 4789 is opened on both clusters for each other's VPC CIDR, and possibly ICMP
echo " Adding VXLAN UDP port 4789 to both clusters security groups"

echo "-----------------------------------------------"
# get security group for both CLUSTER1_NAME & CLUSTER2_NAME
SG1_ID=$(aws ec2 describe-instances --region $CLUSTER1_REGION --filters "Name=tag:Name,Values=*$CLUSTER1_NAME*" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[*].NetworkInterfaces[0].Groups[0].GroupId' --output text)

SG2_ID=$(aws ec2 describe-instances --region $CLUSTER2_REGION --filters "Name=tag:Name,Values=*$CLUSTER2_NAME*" "Name=instance-state-name,Values=running" --query 'Reservations[0].Instances[*].NetworkInterfaces[0].Groups[0].GroupId' --output text)

echo "-----------------------------------------------"
# allow UDP traffic over port 4789 for CLUSTER1_NAME and CLUSTER2_NAME
aws ec2 authorize-security-group-ingress --region $CLUSTER1_REGION --group-id $SG1_ID --protocol udp --port 4789 --cidr $CLUSTER2_VPC_ADDR_SPACE 2>&1
aws ec2 authorize-security-group-ingress --region $CLUSTER2_REGION --group-id $SG2_ID --protocol udp --port 4789 --cidr $CLUSTER1_VPC_ADDR_SPACE 2>&1

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
echo "======================== VPC Peering COMPLETED =========================="