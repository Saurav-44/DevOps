#!/bin/bash
REGION="eu-north-1"
KEY_NAME="AutoKeyPair_$(date +%s)"   
KEY_FILE="$KEY_NAME.pem"
SECURITY_GROUP_NAME="AutoSecurityGroup_$(date +%s)"
TOPIC_NAME="HighCPUAlarmTopic_$(date +%s)"
EMAIL="omf1491@gmail.com"  
INSTANCE_TYPE="t3.micro"


echo "Using AWS Region: $REGION"
echo "Finding latest Amazon Linux 2 AMI ID..."
AMI_ID="ami-042b4708b1d05f512"

echo "Found AMI ID: $AMI_ID"

echo "Creating Key Pair: $KEY_NAME"
aws ec2 create-key-pair --key-name $KEY_NAME --query "KeyMaterial" --output text --region $REGION > $KEY_FILE
chmod 400 $KEY_FILE
echo "Key saved to $KEY_FILE"

echo "Getting default VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region $REGION --query "Vpcs[0].VpcId" --output text)

echo "Creating Security Group: $SECURITY_GROUP_NAME"
SG_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Allow SSH and ICMP" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)

echo "Authorizing inbound rules (SSH and ICMP)..."
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol icmp --port -1 --cidr 0.0.0.0/0 --region $REGION

echo "Security Group ID: $SG_ID"
echo "Finding public subnet ID..."
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=map-public-ip-on-launch,Values=true" \
  --region $REGION \
  --query "Subnets[0].SubnetId" --output text)

echo "Public Subnet ID: $SUBNET_ID"
echo "Launching EC2 instance..."
INSTANCE_ID=$( aws ec2 run-instances \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' \
  --region $REGION --output text )

echo "Instance ID: $INSTANCE_ID"
echo "Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
echo "Instance is running."
echo "Creating SNS topic: $TOPIC_NAME"
TOPIC_ARN=$(aws sns create-topic --name $TOPIC_NAME --region $REGION --query 'TopicArn' --output text)

echo "Subscribing $EMAIL to SNS topic..."
aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint $EMAIL --region $REGION

echo "Please check your email and CONFIRM the SNS subscription!"

ALARM_NAME="HighCPUAlarm-$INSTANCE_ID"
echo "Creating CloudWatch alarm: $ALARM_NAME"

aws cloudwatch put-metric-alarm \
  --alarm-name $ALARM_NAME \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --alarm-actions $TOPIC_ARN \
  --region $REGION

echo "Done! Instance $INSTANCE_ID will trigger alarm and send notification to $EMAIL when CPU > 70%."
echo "You can SSH to the instance using:"
echo "ssh -i $KEY_FILE ec2-user@$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"

