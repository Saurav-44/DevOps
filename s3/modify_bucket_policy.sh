#!/bin/bash
set -euo pipefail

# 2. Modify the bucket policy of an existing S3 bucket.
if [ $# -ne 1 ]; then
  echo "Usage: $0 <bucket-name>"
  exit 1
fi

BUCKET="$1"
REGION="${REGION:-eu-north-1}"

# Define a new public-read policy for objects
cat > /tmp/new_policy.json <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"PublicReadGetObject",
      "Effect":"Allow",
      "Principal":"*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::$BUCKET/*"]
    }
  ]
}
EOF

# Apply the new policy
aws s3api put-bucket-policy \
  --bucket "$BUCKET" \
  --policy file:///tmp/new_policy.json \
  --region "$REGION"

echo "Applied public-read policy to bucket: $BUCKET"
