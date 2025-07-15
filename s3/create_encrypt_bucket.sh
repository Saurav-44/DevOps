BUCKET_NAME="my-bucket-44"
REGION="eu-north-1"  # change to your preferred AWS region

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: Please provide a bucket name."
  echo "Usage: $0 your-bucket-name"
  exit 1
fi

# Create the bucket
echo "Creating bucket: $BUCKET_NAME in region $REGION"
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

if [ $? -ne 0 ]; then
  echo "Bucket creation failed!"
  exit 1
fi

# Enable default encryption on the bucket (AES-256)
echo "Enabling default encryption on bucket: $BUCKET_NAME"
aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

if [ $? -eq 0 ]; then
  echo "Bucket created and encryption enabled successfully."
else
  echo "Failed to enable encryption."
  exit 1
fi

