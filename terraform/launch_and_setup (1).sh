#!/usr/bin/env bash
set -euo pipefail

### === Configuration ===
REGION="${REGION:-us-east-1}"
AMI="${AMI:-ami-0c94855ba95c71c99}"          # change to Ubuntu AMI if desired
INSTANCE_TYPE="${INSTANCE_TYPE:-t2.micro}"
SUBNET_ID="${SUBNET_ID:-subnet-xxxxxxxx}"    # your public subnet ID
SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-sg-xxxxxxxx}"  # allows SSH (port 22)
KEY_NAME="${KEY_NAME:-my-key-pair}"          # name of your EC2 key pair (without .pem)
TERRAFORM_VERSION="${TERRAFORM_VERSION:-1.5.7}"

### === 1. Launch the EC2 instance ===
echo "Launching instance in subnet ${SUBNET_ID}..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI" \
  --instance-type "$INSTANCE_TYPE" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --key-name "$KEY_NAME" \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' \
  --output text \
  --region "$REGION")

echo "-> Instance launched: $INSTANCE_ID"
echo "Waiting for instance to be in 'running' state..."
aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION"

### === 2. Get its public IP ===
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text \
  --region "$REGION")

echo "-> Instance Public IP: $PUBLIC_IP"
echo "Waiting for SSH to become available..."
sleep 30

### === 3. Generate the remote installer script ===
cat > install_terraform.sh <<EOF
#!/usr/bin/env bash
set -e

sudo yum update -y
sudo yum install -y unzip

TVER=${TERRAFORM_VERSION}
cd /tmp
wget https://releases.hashicorp.com/terraform/\${TVER}/terraform_\${TVER}_linux_amd64.zip
unzip terraform_\${TVER}_linux_amd64.zip
sudo mv terraform /usr/local/bin/

mkdir -p ~/terraform_project
cat > ~/terraform_project/main.tf <<TF
provider "aws" {
  region = "${REGION}"
}
TF

cd ~/terraform_project
terraform init -input=false
EOF

chmod +x install_terraform.sh

### === 4. Copy & execute on the instance ===
echo "Copying installer to instance..."
scp -o StrictHostKeyChecking=no \
    -i "${KEY_NAME}.pem" \
    install_terraform.sh \
    ec2-user@"${PUBLIC_IP}":~/install_terraform.sh

echo "Running installer on instance..."
ssh -o StrictHostKeyChecking=no \
    -i "${KEY_NAME}.pem" \
    ec2-user@"${PUBLIC_IP}" \
    "chmod +x ~/install_terraform.sh && ~/install_terraform.sh"

echo "✔️ Terraform should now be installed on ${PUBLIC_IP} and ~/terraform_project initialized."
