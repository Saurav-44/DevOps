#!/bin/bash
cd infra
terraform init
terraform apply -auto-approve | tee ../terraform_output.txt