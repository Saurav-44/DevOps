#!/bin/bash

REGION="eu-north-1"         # set your region
INSTANCE_ID="i-0195d5b5b6d08caec"  # Replace with your EC2 instance ID from previous step
TOPIC_ARN="arn:aws:sns:eu-north-1:349854929230:HighCPUAlarmTopic_1752657345"  # Replace with your SNS Topic ARN

# Alarms definitions (name, metric, threshold, comparison)
declare -A alarms=(
  ["CPUUtilizationHigh"]="CPUUtilization GreaterThanThreshold 70 Average"
  ["StatusCheckFailed"]="StatusCheckFailed_Instance GreaterThanOrEqualToThreshold 1 Maximum"
  ["DiskReadOpsHigh"]="DiskReadOps GreaterThanThreshold 1000 Sum"
  ["NetworkInHigh"]="NetworkIn GreaterThanThreshold 1000000 Sum"
  ["NetworkOutHigh"]="NetworkOut GreaterThanThreshold 1000000 Sum"
)

echo "Creating CloudWatch alarms..."

for alarm in "${!alarms[@]}"; do
  read -r metric comparison threshold stat <<< "${alarms[$alarm]}"
  
  aws cloudwatch put-metric-alarm \
    --alarm-name "$alarm-$INSTANCE_ID" \
    --metric-name "$metric" \
    --namespace "AWS/EC2" \
    --statistic "$stat" \
    --period 300 \
    --threshold "$threshold" \
    --comparison-operator "$comparison" \
    --evaluation-periods 1 \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --alarm-actions $TOPIC_ARN \
    --region $REGION
  
  echo "Alarm $alarm created."
done

echo "Creating CloudWatch dashboard..."

DASHBOARD_NAME="EC2InstanceAlarms-$INSTANCE_ID"
DASHBOARD_BODY=$(cat <<EOF
{
  "widgets": [
    {
      "type": "alarm",
      "x": 0,
      "y": 0,
      "width": 24,
      "height": 6,
      "properties": {
        "alarms": [
          "$(printf '%s-%s",' "${!alarms[@]}" "$INSTANCE_ID" | sed 's/,$//')"
        ],
        "title": "EC2 Instance Alarms"
      }
    }
  ]
}
EOF
)

# Fix alarms array in dashboard JSON with correct alarm names
ALARM_NAMES_JSON=$(printf '"%s-%s",' "${!alarms[@]}" "$INSTANCE_ID" | sed 's/,$//')
DASHBOARD_BODY=$(cat <<EOF
{
  "widgets": [
    {
      "type": "alarm",
      "x": 0,
      "y": 0,
      "width": 24,
      "height": 6,
      "properties": {
        "alarms": [
          $ALARM_NAMES_JSON
        ],
        "title": "EC2 Instance Alarms"
      }
    }
  ]
}
EOF
)

aws cloudwatch put-dashboard --dashboard-name $DASHBOARD_NAME --dashboard-body "$DASHBOARD_BODY" --region $REGION

echo "Dashboard $DASHBOARD_NAME created successfully."

