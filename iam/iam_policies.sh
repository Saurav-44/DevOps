#!/bin/bash

read -p "Enter IAM username to create: " username

aws iam create-user --user-name "$username"

aws iam attach-user-policy --user-name "$username" --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

aws iam attach-user-policy --user-name "$username" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam attach-user-policy --user-name "$username" --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

echo "User '$username' created and policies attached."
