#!/bin/bash
set -euo pipefail

# Replace with your instance ID and region
INSTANCE_ID="i-xxxxxxxxxxxxxxxxx"
REGION="us-east-1"
DASHBOARD_NAME="EC2MonitoringDashboard"

cat <<EOF > dashboard.json
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
          [ "AWS/EC2", "CPUUtilization", "InstanceId", "$INSTANCE_ID" ],
          [ ".", "NetworkIn", ".", "." ],
          [ ".", "NetworkOut", ".", "." ],
          [ ".", "DiskReadOps", ".", "." ],
          [ ".", "DiskWriteOps", ".", "." ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "$REGION",
        "title": "EC2 Metrics for $INSTANCE_ID"
      }
    }
  ]
}
EOF

aws cloudwatch put-dashboard --dashboard-name "$DASHBOARD_NAME" --dashboard-body file://dashboard.json --region "$REGION"
echo "Dashboard '$DASHBOARD_NAME' created."
