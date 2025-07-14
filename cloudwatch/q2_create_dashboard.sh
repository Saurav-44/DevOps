#!/usr/bin/env bash
set -euo pipefail

# ─────── CONFIG ──────────
INSTANCE_ID="i-0123456789abcdef0"        # ← your EC2 instance ID
REGION="us-east-1"                       # ← your AWS region
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:123456789012:cpuAlarmTopic"  # ← from Q1
DASHBOARD_NAME="EC2MonitoringDashboard"

# ─────── 1. Create additional CloudWatch alarms ──────────

# 1a. System status check failure
aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "StatusCheckFailed_Instance-$INSTANCE_ID" \
  --alarm-description "EC2 instance status check failed" \
  --metric-name StatusCheckFailed_Instance \
  --namespace AWS/EC2 \
  --statistic Maximum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
  --alarm-actions "$SNS_TOPIC_ARN"

# 1b. Network In high
aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "NetworkInHigh-$INSTANCE_ID" \
  --alarm-description "High network in" \
  --metric-name NetworkIn \
  --namespace AWS/EC2 \
  --statistic Sum \
  --period 300 \
  --threshold 10000000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
  --alarm-actions "$SNS_TOPIC_ARN"

# 1c. Network Out high
aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "NetworkOutHigh-$INSTANCE_ID" \
  --alarm-description "High network out" \
  --metric-name NetworkOut \
  --namespace AWS/EC2 \
  --statistic Sum \
  --period 300 \
  --threshold 10000000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
  --alarm-actions "$SNS_TOPIC_ARN"

# 1d. Disk read ops high
aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "DiskReadOpsHigh-$INSTANCE_ID" \
  --alarm-description "High disk read ops" \
  --metric-name DiskReadOps \
  --namespace AWS/EC2 \
  --statistic Sum \
  --period 300 \
  --threshold 10000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
  --alarm-actions "$SNS_TOPIC_ARN"

# 1e. Disk write ops high
aws cloudwatch put-metric-alarm \
  --region "$REGION" \
  --alarm-name "DiskWriteOpsHigh-$INSTANCE_ID" \
  --alarm-description "High disk write ops" \
  --metric-name DiskWriteOps \
  --namespace AWS/EC2 \
  --statistic Sum \
  --period 300 \
  --threshold 10000 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
  --alarm-actions "$SNS_TOPIC_ARN"

echo "✓ Created 5 additional alarms."

# ─────── 2. Build dashboard JSON ──────────

cat > dashboard.json <<EOF
{
  "widgets": [
    {
      "type": "alarm",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "alarms": [
          "HighCPU-$INSTANCE_ID",
          "StatusCheckFailed_Instance-$INSTANCE_ID",
          "NetworkInHigh-$INSTANCE_ID",
          "NetworkOutHigh-$INSTANCE_ID",
          "DiskReadOpsHigh-$INSTANCE_ID",
          "DiskWriteOpsHigh-$INSTANCE_ID"
        ]
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 6, "width": 12, "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/EC2", "CPUUtilization",         "InstanceId", "$INSTANCE_ID" ],
          [ ".",       "NetworkIn",              ".",          "."            ],
          [ ".",       "NetworkOut",             ".",          "."            ],
          [ ".",       "DiskReadOps",            ".",          "."            ],
          [ ".",       "DiskWriteOps",           ".",          "."            ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "$REGION",
        "title": "Key EC2 Metrics for $INSTANCE_ID"
      }
    }
  ]
}
EOF

echo "✓ dashboard.json written."

# ─────── 3. Push dashboard to CloudWatch ──────────
aws cloudwatch put-dashboard \
  --region "$REGION" \
  --dashboard-name "$DASHBOARD_NAME" \
  --dashboard-body file://dashboard.json

echo "✓ Dashboard '$DASHBOARD_NAME' created."
