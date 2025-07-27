#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo docker pull saurav445/frontend-app:latest
sudo docker run -d -p 80:80 saurav445/frontend-app:latest