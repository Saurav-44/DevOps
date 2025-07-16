#1/bin/bash

read -p "Enter the AWS username to create: " name

aws iam create-user --user-name "$name"

USER_ID=$(aws iam get-user --user-name "$name" --query 'User.UserId' --output text)
USER_NAME=$(aws iam get-user --user-name "$name" --query 'User.UserName' --output text)
TIMESTAMP=$(date)

echo "UserID: $USER_ID"
echo "UserName: $USER_NAME"
echo "TimeStamp: $TIMESTAMP"
