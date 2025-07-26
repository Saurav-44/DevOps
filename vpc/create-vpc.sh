#!/usr/bin/env bash
set -e

# 1. install Docker
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker

# 2. pull & run your frontend image
docker pull YOUR_DOCKERHUB_USER/frontend:latest
docker run -d --name frontend \
  -p 8080:8080 \
  YOUR_DOCKERHUB_USER/frontend:latest
