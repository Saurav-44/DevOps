#!/bin/bash
set -euo pipefail

# Configuration (override via env vars)
REGION="${REGION:-us-east-1}"
VPC_CIDR="${VPC_CIDR:-10.0.0.0/16}"
PUBLIC_SUBNET_CIDR="${PUBLIC_SUBNET_CIDR:-10.0.1.0/24}"
PRIVATE_SUBNET_CIDR="${PRIVATE_SUBNET_CIDR:-10.0.2.0/24}"
AZ="${AZ:-${REGION}a}"
TAG_NAME="${TAG_NAME:-MyVPC}"

# Create the VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block "$VPC_CIDR" --region "$REGION" \
  --query 'Vpc.VpcId' --output text)
aws ec2 wait vpc-available --vpc-ids "$VPC_ID" --region "$REGION"
aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value="$TAG_NAME" --region "$REGION"

# Create subnets
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" \
  --cidr-block "$PUBLIC_SUBNET_CIDR" --availability-zone "$AZ" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id "$VPC_ID" \
  --cidr-block "$PRIVATE_SUBNET_CIDR" --availability-zone "$AZ" \
  --region "$REGION" --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources "$PUBLIC_SUBNET_ID" "$PRIVATE_SUBNET_ID" \
  --tags Key=Name,Value="${TAG_NAME}-public" Key=Name,Value="${TAG_NAME}-private" \
  --region "$REGION"

# Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --region "$REGION" \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION"
aws ec2 create-tags --resources "$IGW_ID" --tags Key=Name,Value="${TAG_NAME}-igw" --region "$REGION"

# Route Table for public subnet
RTB_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --region "$REGION" \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id "$RTB_ID" --subnet-id "$PUBLIC_SUBNET_ID" --region "$REGION"
aws ec2 create-route --route-table-id "$RTB_ID" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$IGW_ID" --region "$REGION"
aws ec2 create-tags --resources "$RTB_ID" --tags Key=Name,Value="${TAG_NAME}-public-rt" --region "$REGION"

# Enable auto-assign public IP on public subnet
aws ec2 modify-subnet-attribute --subnet-id "$PUBLIC_SUBNET_ID" --map-public-ip-on-launch --region "$REGION"

echo "VPC $VPC_ID with public subnet $PUBLIC_SUBNET_ID and private subnet $PRIVATE_SUBNET_ID created."
