#!/usr/bin/env bash
# Installs Docker, pulls your Node.js/MySQL backend image, and runs it.

# 1. Install Docker & CLI
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# 2. Run backend container (listens on 3000)
docker pull $1/node-mysql-backend:latest
docker run -d \
  --name backend \
  -e MYSQL_HOST=localhost \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=pass123 \
  -e MYSQL_DATABASE=userdata \
  $1/node-mysql-backend:latest
