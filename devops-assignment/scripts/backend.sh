#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo docker pull saurav445/backend-app:latest
sudo docker run -d -p 3000:3000 saurav445/backend-app:latest