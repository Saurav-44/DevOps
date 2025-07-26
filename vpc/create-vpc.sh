#!/usr/bin/env bash
set -euo pipefail

# from app/scripts:
cd ../backend
docker build -t saurav123/node-mysql-backend:latest .
docker push saurav123/node-mysql-backend:latest

cd ../frontend
docker build -t saurav123/simple-frontend:latest .
docker push saurav123/simple-frontend:latest

# back to project root
cd ../../

