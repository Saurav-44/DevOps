# From project root:

# 1. Backend (Node.js + MySQL)
cd app/backend
docker build -t <YOUR_DOCKERHUB_USER>/node-mysql-backend:latest .
docker push <YOUR_DOCKERHUB_USER>/node-mysql-backend:latest

# 2. Frontend (static HTML + simple JS form)
cd ../frontend
docker build -t <YOUR_DOCKERHUB_USER>/simple-frontend:latest .
docker push <YOUR_DOCKERHUB_USER>/simple-frontend:latest

cd ../../
