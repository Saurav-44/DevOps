#!/usr/bin/env bash
# Installs Docker, pulls your static‐frontend image, and injects backend IP.

BACKEND_IP=$1
DH_USER=$2

yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Pull & run, passing backend URL as env var:
docker pull $DH_USER/simple-frontend:latest
docker run -d \
  --name frontend \
  -p 80:80 \
  -e BACKEND_URL="http://$BACKEND_IP:3000" \
  $DH_USER/simple-frontend:latest
