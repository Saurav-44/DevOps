#!/bin/bash

# Variables
BUCKET_NAME="my-website-bucket-123456"
REGION="us-east-1"

# Create S3 bucket
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# Enable static website hosting
aws s3 website s3://$BUCKET_NAME/ --index-document index.html --error-document error.html

# Upload HTML files
aws s3 cp index.html s3://$BUCKET_NAME/
aws s3 cp error.html s3://$BUCKET_NAME/

# Output website URL
echo "Website URL: http://$BUCKET_NAME.s3-website-$REGION.amazonaws.com"
