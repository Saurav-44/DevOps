#!/bin/bash

# Configuration
REGION="${REGION:-eu-north-1}"
KEY_NAME="ubuntu-key1"
KEY_FILE="$KEY_NAME.pem"
SECURITY_GROUP_NAME="ubuntu-sg1"
INSTANCE_TYPE="t3.micro"
SCRIPT_FILE="setup.sh"


echo "Creating key pair: $KEY_NAME\n"
aws ec2 create-key-pair --region "$REGION" --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"
echo $KEY_FILE
chmod 400 "$KEY_FILE"
echo "Key saved to $KEY_FILE"


echo " Creating security group: $SECURITY_GROUP_NAME"
SECURITY_GROUP_ID=$(aws ec2 create-security-group --region "$REGION" --group-name "$SECURITY_GROUP_NAME" --description "Security group for Ubuntu instance" --query 'GroupId' --output text)
echo $SECURITY_GROUP_ID
echo "Security group created: $SECURITY_GROUP_ID"


#Alternative ways to extract Security Group ID:
# SECURITY_GROUP_ID=$(aws ec2 create-security-group ... --output text | awk '{print $1}')
# SECURITY_GROUP_ID=$(aws ec2 create-security-group ... --output text | cut -f1)
# SECURITY_GROUP_ID=$(aws ec2 create-security-group ... --output text | sed -n '1p')
# SECURITY_GROUP_ID=$(aws ec2 create-security-group ... --output text | grep -o 'sg-[a-zA-Z0-9]*')




# Step 3: Authorize SSH access
echo "Authorizing SSH (port 22) access"
aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SECURITY_GROUP_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0


echo "Fetching latest Ubuntu 22.04 LTS AMI ID..."
AMI_ID=$(aws ec2 describe-images \
  --region "$REGION" \
  --owners 099720109477 \
  --filters \
    "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
    "Name=architecture,Values=x86_64" \
    "Name=virtualization-type,Values=hvm" \
    "Name=root-device-type,Values=ebs" \
  --query 'Images[*].[ImageId,CreationDate]' \
  --output text | \
  sort -k2 -r | \
  head -n 1 | \
  awk '{print $1}')

echo "Latest AMI ID found: $AMI_ID"
# Alternative ways to extract Instance ID:
# Alternative 1: Using cut
# AMI_ID=$(aws ec2 describe-images --region "$REGION" --owners 099720109477 \
#   --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
#   "Name=architecture,Values=x86_64" "Name=virtualization-type,Values=hvm" \
#   "Name=root-device-type,Values=ebs" \
#   --query 'Images[*].[ImageId,CreationDate]' --output text | sort -k2 -r | head -n 1 | cut -f1)

# Alternative 2: Using sed + awk
# AMI_ID=$(aws ec2 describe-images --region "$REGION" --owners 099720109477 \
#   --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
#   "Name=architecture,Values=x86_64" "Name=virtualization-type,Values=hvm" \
#   "Name=root-device-type,Values=ebs" \
#   --query 'Images[*].[ImageId,CreationDate]' --output text | sort -k2 -r | sed -n '1p' | awk '{print $1}')

# Alternative 3: Using grep -o
# AMI_ID=$(aws ec2 describe-images --region "$REGION" --owners 099720109477 \
#   --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
#   "Name=architecture,Values=x86_64" "Name=virtualization-type,Values=hvm" \
#   "Name=root-device-type,Values=ebs" \
#   --query 'Images[*].[ImageId,CreationDate]' --output text | sort -k2 -r | head -n 1 | grep -o 'ami-[a-zA-Z0-9]\+')
# Step 5: Launch the EC2 instance

echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --query "Instances[0].InstanceId" \
  --output text)

echo "Instance launched! ID: $INSTANCE_ID"
# Alternative ways to extract Instance ID:
# INSTANCE_ID=$(aws ec2 run-instances ... --output text | awk '{print $1}')
# INSTANCE_ID=$(aws ec2 run-instances ... --output text | cut -f1)
# INSTANCE_ID=$(aws ec2 run-instances ... --output text | sed -n '1p')
# INSTANCE_ID=$(aws ec2 run-instances ... --output text | grep -o 'i-[a-zA-Z0-9]*')



aws ec2 wait instance-running \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID"



aws ec2 wait instance-status-ok \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID"

# Step 7: Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)


echo "Public IP: $PUBLIC_IP"
echo "Connect using: ssh -i $KEY_FILE ubuntu@$PUBLIC_IP"

echo "Sending $SCRIPT_FILE to EC2 instance at $PUBLIC_IP..."
scp -o StrictHostKeyChecking=no -i "$KEY_FILE" "$SCRIPT_FILE" ubuntu@"$PUBLIC_IP":~
