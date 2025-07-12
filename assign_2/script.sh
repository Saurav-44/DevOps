#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#
# CONFIGURATION
#
REGION="${REGION:-eu-north-1}"
KEY_NAME="ubuntu-key5"
KEY_FILE="${KEY_NAME}.pem"
SECURITY_GROUP_NAME="ubuntu-sg5"
INSTANCE_TYPE="t3.micro"
SCRIPT_FILE="setup.sh"

echo "→ Using AWS region: $REGION"

#
# PRECHECK: ensure your bootstrap script is present
#
if [[ ! -f "$SCRIPT_FILE" ]]; then
  echo "❌  '$SCRIPT_FILE' not found in $(pwd)" >&2
  exit 1
fi

#
# STEP 1: Create a new key pair
#
echo "→ Creating key pair: $KEY_NAME"
aws ec2 create-key-pair \
  --region "$REGION" \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "$KEY_FILE"
chmod 400 "$KEY_FILE"
echo "✔  Key saved to $KEY_FILE (chmod 400)"

#
# STEP 2: Create a security group
#
echo "→ Creating security group: $SECURITY_GROUP_NAME"
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
  --region "$REGION" \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "SSH access for Ubuntu" \
  --query 'GroupId' \
  --output text)
echo "✔  Security group created: $SECURITY_GROUP_ID"

#
# STEP 3: Open port 22
#
echo "→ Authorizing SSH (port 22)"
aws ec2 authorize-security-group-ingress \
  --region "$REGION" \
  --group-id "$SECURITY_GROUP_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 \
  --output text >/dev/null
echo "✔  Port 22 open"

#
# STEP 4: Find the latest Ubuntu 22.04 AMI
#
echo "→ Fetching latest Ubuntu 22.04 AMI"
AMI_ID=$(aws ec2 describe-images \
    --region "$REGION" \
    --owners 099720109477 \
    --filters \
      "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
      "Name=architecture,Values=x86_64" \
      "Name=virtualization-type,Values=hvm" \
      "Name=root-device-type,Values=ebs" \
    --query 'Images[*].[ImageId,CreationDate]' \
    --output text | sort -k2r | head -n1 | awk '{print $1}')
echo "✔  AMI ID: $AMI_ID"

#
# STEP 5: Launch the EC2 instance
#
echo "→ Launching instance ($INSTANCE_TYPE)…"
INSTANCE_ID=$(aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "✔  Instance launched: $INSTANCE_ID"

#
# STEP 6: Wait for it to be running & pass status checks
#
echo "→ Waiting for 'running' state…"
aws ec2 wait instance-running \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID"

echo "→ Waiting for system + instance status checks…"
aws ec2 wait instance-status-ok \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID"

#
# STEP 7: Grab its public IP
#
PUBLIC_IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)
echo "✔  Public IP: $PUBLIC_IP"

#
# STEP 8: Poll SSH until ready
#
echo -n "→ Waiting for SSH on $PUBLIC_IP"
until ssh -o BatchMode=yes \
          -o ConnectTimeout=5 \
          -o StrictHostKeyChecking=no \
          -i "$KEY_FILE" ubuntu@"$PUBLIC_IP" 'exit' &>/dev/null
do
  printf "."
  sleep 3
done
echo " up!"

#
# STEP 9: Copy over your setup script
#
echo "→ Uploading $SCRIPT_FILE to ubuntu@$PUBLIC_IP:~/"
scp -o StrictHostKeyChecking=no \
    -i "$KEY_FILE" \
    "$SCRIPT_FILE" \
    ubuntu@"$PUBLIC_IP":~/

echo
echo "🎉 All set! Connect with:"
echo "    ssh -i $KEY_FILE ubuntu@$PUBLIC_IP"
