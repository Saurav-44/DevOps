#!/usr/bin/env bash
set -euo pipefail

# ─────── CONFIG ──────────
REGION="${REGION:-us-east-1}"
AMI_ID="${AMI_ID:-ami-0c94855ba95c71c99}"     # Amazon Linux 2 in us-east-1
INSTANCE_TYPE="${INSTANCE_TYPE:-t2.micro}"
KEY_NAME="${KEY_NAME:-my-key-pair}"           # replace with your key
SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-sg-0123456789abcdef0}"  # replace
SUBNET_TAG_KEY="${SUBNET_TAG_KEY:-Name}"
SUBNET_TAG_VALUE="${SUBNET_TAG_VALUE:-PublicSubnet}"

SNS_TOPIC_NAME="${SNS_TOPIC_NAME:-cpuAlarmTopic}"

# ─────── 1. fetch public subnet ID ──────────
echo "Fetching public subnet ID..."
SUBNET_ID=$(aws ec2 describe‐subnets \
  --region "$REGION" \
  --filters "Name=tag:${SUBNET_TAG_KEY},Values=${SUBNET_TAG_VALUE}" \
  --query 'Subnets[0].SubnetId' --output text)

echo "Public subnet ID = $SUBNET_ID"

# ─────── 2. launch EC2 instance ──────────
echo "Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run‐instances \
  --region "$REGION" \
  --image‐id "$AMI_ID" \
  --instance‐type "$INSTANCE_TYPE" \
  --key‐name "$KEY_NAME" \
  --security‐group‐ids "$SECURITY_GROUP_ID" \
  --subnet‐id "$SUBNET_ID" \
  --associate‐public‐ip‐address \
  --query 'Instances[0].InstanceId' --output text)

echo "Instance launched: $INSTANCE_ID"

# ─────── 3. create SNS topic ──────────
echo "Creating SNS topic..."
SNS_TOPIC_ARN=$(aws sns create‐topic \
  --region "$REGION" \
  --name "$SNS_TOPIC_NAME" \
  --output text)

echo "SNS topic ARN = $SNS_TOPIC_ARN"

# (optional) subscribe your email so you actually get notifications:
# aws sns subscribe --topic-arn "$SNS_TOPIC_ARN" --protocol email --notification-endpoint you@example.com

# ─────── 4. create CloudWatch alarm ──────────
ALARM_NAME="HighCPU-${INSTANCE_ID}"
echo "Creating CloudWatch alarm '$ALARM_NAME'..."
aws cloudwatch put‐metric‐alarm \
  --region "$REGION" \
  --alarm‐name "$ALARM_NAME" \
  --alarm‐description "Alert when CPU > 70%" \
  --metric‐name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison‐operator GreaterThanThreshold \
  --evaluation‐periods 1 \
  --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
  --alarm‐actions "$SNS_TOPIC_ARN"

echo "Done! Alarm '$ALARM_NAME' will notify via SNS topic '$SNS_TOPIC_ARN' when CPU > 70%."
