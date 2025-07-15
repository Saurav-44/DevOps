#!/bin/bash
set -euo pipefail

# 1. Create a random-named S3 bucket, upload this script, list and delete it.
REGION="${REGION:-eu-north-1}"

# Generate a random bucket name
BUCKET="bucket-$(date +%s%N | sha256sum | head -c 8)"

# Create the S3 bucket
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"
echo "Created bucket: $BUCKET"

# Upload this script to the bucket
aws s3 cp "\$0" "s3://$BUCKET/"
echo "Uploaded script to s3://$BUCKET/"

# Display bucket contents
echo "Bucket contents:"
aws s3 ls "s3://$BUCKET/"

# Delete the bucket and its contents
aws s3 rb "s3://$BUCKET" --force
echo "Deleted bucket: $BUCKET"
