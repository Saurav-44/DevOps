#!/bin/bash
set -euo pipefail

# 3. Create EC2, show public DNS, copy & run a remote setup script.
REGION="${REGION:-eu-north-1}"

# Determine latest Ubuntu 22.04 AMI
AMI_ID=$(aws ec2 describe-images --region "$REGION" --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
            "Name=state,Values=available" \
  --query 'Images | sort_by(@,&CreationDate)[-1].ImageId' \
  --output text)

# Create key pair
KEY_NAME="remote-key-$(date +%s)"
KEY_FILE="${KEY_NAME}.pem"
aws ec2 create-key-pair --region "$REGION" --key-name "$KEY_NAME" \
  --query 'KeyMaterial' --output text > "$KEY_FILE"
chmod 400 "$KEY_FILE"

# Create a security group allowing SSH
SG_NAME="remote-sg-$(date +%s)"
VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 create-security-group --region "$REGION" \
  --group-name "$SG_NAME" --description "Allow SSH" --vpc-id "$VPC_ID" \
  --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --region "$REGION" \
  --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --count 1 \
  --query 'Instances[0].InstanceId' --output text)

echo "Launching EC2 instance: $INSTANCE_ID"
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

# Retrieve and display the public DNS
PUBLIC_DNS=$(aws ec2 describe-instances --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicDnsName' \
  --output text)
echo "Instance Public DNS: $PUBLIC_DNS"

# Copy and execute the remote setup script
scp -o StrictHostKeyChecking=no -i "$KEY_FILE" remote_setup.sh ubuntu@"$PUBLIC_DNS":~/remote_setup.sh
ssh -o StrictHostKeyChecking=no -i "$KEY_FILE" ubuntu@"$PUBLIC_DNS" "bash ~/remote_setup.sh"
