#!/usr/bin/env bash
set -euo pipefail

# from app/scripts → go build & push the backend
cd ../backend
docker build -t saurav445/node-mysql-backend:latest .
docker push saurav445/node-mysql-backend:latest

# now build & push the frontend
cd ../frontend
docker build -t saurav445/simple-frontend:latest .
docker push saurav445/simple-frontend:latest

echo "✅ Images built & pushed successfully."
