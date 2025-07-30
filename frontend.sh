#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io
sudo systemctl enable docker 
sudo systemctl start docker

sudo docker pull partha3/frontend-app
sudo docker run -d -p  5000:5000 --name frontend-container partha3/frontend-app
