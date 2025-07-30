#!/bin/bash

# Update system packages
sudo apt update -y

# Install Docker
sudo apt install -y docker.io

# Enable Docker on boot
sudo systemctl enable docker
sudo systemctl start docker

# Pull MySQL Docker image
sudo docker pull mysql:5.7

# Run MySQL container
sudo docker run -d \
  --name mysql-db \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=app_db \
  -e MYSQL_USER=user \
  -e MYSQL_PASSWORD=userpass \
  -p 3306:3306 \
  mysql:5.7
