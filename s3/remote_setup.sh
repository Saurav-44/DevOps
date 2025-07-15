#!/bin/bash
set -euo pipefail

# Remote script: create a new bucket and attach an access point.
REGION="${REGION:-eu-north-1}"

# Generate unique names
BUCKET="app-bucket-$(date +%s%N | sha256sum | head -c 8)"
AP_NAME="${BUCKET}-ap"
ACCOUNT_ID=$(aws sts get-caller-identity --region "$REGION" --query Account --output text)

# Create the S3 bucket
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"
echo "Created bucket: $BUCKET"

# Create the S3 Access Point
aws s3control create-access-point \
  --account-id "$ACCOUNT_ID" \
  --name "$AP_NAME" \
  --bucket "$BUCKET" \
  --region "$REGION"
echo "Created access point: $AP_NAME for bucket: $BUCKET"
