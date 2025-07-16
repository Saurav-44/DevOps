cat << 'EOF' > setup_vpc.sh
#!/bin/bash
set -euo pipefail

# Configuration (override via env vars)
REGION="\${REGION:-eu-north-1}"
VPC_CIDR="\${VPC_CIDR:-10.0.0.0/16}"
PUBLIC_SUBNET_CIDR="\${PUBLIC_SUBNET_CIDR:-10.0.1.0/24}"
PRIVATE_SUBNET_CIDR="\${PRIVATE_SUBNET_CIDR:-10.0.2.0/24}"
AZ="\${AZ:-\${REGION}a}"
TAG_NAME="\${TAG_NAME:-MyVPC}"

# Optional parameters for private EC2 launch
your_key_name="\${KEY_NAME:-my-key-pair}"
your_security_group_id="\${SECURITY_GROUP_ID:-default}"
private_ami="\${PRIVATE_AMI:-ami-0c94855ba95c71c99}"  # Amazon Linux 2
private_instance_type="\${PRIVATE_INSTANCE_TYPE:-t2.micro}"

# 1. Create the VPC
VPC_ID=\$(aws ec2 create-vpc --cidr-block "\$VPC_CIDR" --region "\$REGION" \
  --query 'Vpc.VpcId' --output text)
aws ec2 wait vpc-available --vpc-ids "\$VPC_ID" --region "\$REGION"
aws ec2 create-tags --resources "\$VPC_ID" --tags Key=Name,Value="\$TAG_NAME" --region "\$REGION"
echo "Created VPC: \$VPC_ID"

# 2. Create subnets
PUBLIC_SUBNET_ID=\$(aws ec2 create-subnet --vpc-id "\$VPC_ID" \
  --cidr-block "\$PUBLIC_SUBNET_CIDR" --availability-zone "\$AZ" \
  --region "\$REGION" --query 'Subnet.SubnetId' --output text)

PRIVATE_SUBNET_ID=\$(aws ec2 create-subnet --vpc-id "\$VPC_ID" \
  --cidr-block "\$PRIVATE_SUBNET_CIDR" --availability-zone "\$AZ" \
  --region "\$REGION" --query 'Subnet.SubnetId' --output text)

aws ec2 create-tags --resources "\$PUBLIC_SUBNET_ID" "\$PRIVATE_SUBNET_ID" \
  --tags Key=Name,Value="\${TAG_NAME}-public" Key=Name,Value="\${TAG_NAME}-private" \
  --region "\$REGION"

echo "Created public subnet: \$PUBLIC_SUBNET_ID"
echo "Created private subnet: \$PRIVATE_SUBNET_ID"

# 3. Internet Gateway and public route table
IGW_ID=\$(aws ec2 create-internet-gateway --region "\$REGION" \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "\$IGW_ID" --vpc-id "\$VPC_ID" --region "\$REGION"
aws ec2 create-tags --resources "\$IGW_ID" --tags Key=Name,Value="\${TAG_NAME}-igw" --region "\$REGION"

RTB_ID=\$(aws ec2 create-route-table --vpc-id "\$VPC_ID" --region "\$REGION" \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id "\$RTB_ID" --subnet-id "\$PUBLIC_SUBNET_ID" --region "\$REGION"
aws ec2 create-route --route-table-id "\$RTB_ID" --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "\$IGW_ID" --region "\$REGION"
aws ec2 create-tags --resources "\$RTB_ID" --tags Key=Name,Value="\${TAG_NAME}-public-rt" --region "\$REGION"
aws ec2 modify-subnet-attribute --subnet-id "\$PUBLIC_SUBNET_ID" --map-public-ip-on-launch --region "\$REGION"

echo "Configured public route table: \$RTB_ID"

# 4. Allocate (or reuse) Elastic IP and create NAT Gateway
echo "Allocating Elastic IP..."
set +e
EIP_ALLOC_ID=\$(aws ec2 allocate-address --domain vpc --region "\$REGION" \
  --query 'AllocationId' --output text 2>/dev/null)
ALLOC_EXIT=\$?
set -e

if [ \$ALLOC_EXIT -ne 0 ] ; then
  echo "EIP limit reached — reusing an existing Elastic IP"
  EIP_ALLOC_ID=\$(aws ec2 describe-addresses \
    --filters Name=domain,Values=vpc \
    --query 'Addresses[0].AllocationId' --output text)
  if [ -z "\$EIP_ALLOC_ID" ]; then
    echo "ERROR: No VPC Elastic IPs available to reuse. Please release or request more." >&2
    exit 1
  fi
fi

aws ec2 create-tags --resources "\$EIP_ALLOC_ID" \
  --tags Key=Name,Value="\${TAG_NAME}-eip" --region "\$REGION"

NAT_GW_ID=\$(aws ec2 create-nat-gateway \
  --subnet-id "\$PUBLIC_SUBNET_ID" \
  --allocation-id "\$EIP_ALLOC_ID" \
  --region "\$REGION" \
  --query 'NatGateway.NatGatewayId' --output text)
aws ec2 wait nat-gateway-available --nat-gateway-ids "\$NAT_GW_ID" --region "\$REGION"
aws ec2 create-tags --resources "\$NAT_GW_ID" \
  --tags Key=Name,Value="\${TAG_NAME}-nat-gateway" --region "\$REGION"
echo "Created NAT Gateway: \$NAT_GW_ID (EIP: \$EIP_ALLOC_ID)"

# 5. Private route table and route to NAT
PRIVATE_RTB_ID=\$(aws ec2 create-route-table --vpc-id "\$VPC_ID" --region "\$REGION" \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id "\$PRIVATE_RTB_ID" --subnet-id "\$PRIVATE_SUBNET_ID" --region "\$REGION"
aws ec2 create-route --route-table-id "\$PRIVATE_RTB_ID" --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id "\$NAT_GW_ID" --region "\$REGION"
aws ec2 create-tags --resources "\$PRIVATE_RTB_ID" \
  --tags Key=Name,Value="\${TAG_NAME}-private-rt" --region "\$REGION"

echo "Configured private route table: \$PRIVATE_RTB_ID"

# 6. Launch an EC2 instance in the private subnet
INSTANCE_ID=\$(aws ec2 run-instances \
  --image-id "\$private_ami" \
  --instance-type "\$private_instance_type" \
  --subnet-id "\$PRIVATE_SUBNET_ID" \
  --security-group-ids "\$your_security_group_id" \
  --key-name "\$your_key_name" \
  --associate-public-ip-address false \
  --region "\$REGION" \
  --query 'Instances[0].InstanceId' --output text)

aws ec2 create-tags --resources "\$INSTANCE_ID" --tags Key=Name,Value="\${TAG_NAME}-private-instance" --region "\$REGION"
aws ec2 wait instance-running --instance-ids "\$INSTANCE_ID" --region "\$REGION"
echo "Launched private EC2 instance: \$INSTANCE_ID"

# 7. Check if instance has a public IP (reachability test)
PUB_IP=\$(aws ec2 describe-instances --instance-ids "\$INSTANCE_ID" --region "\$REGION" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text || echo "None")

if [ -z "\$PUB_IP" ] || [ "\$PUB_IP" = "None" ]; then
  echo "Instance \$INSTANCE_ID has no public IP and is not reachable from the Internet."
else
  echo "Instance \$INSTANCE_ID public IP: \$PUB_IP"
fi
EOF

chmod +x setup_vpc.sh
