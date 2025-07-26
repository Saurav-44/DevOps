#!/usr/bin/env bash
set -euo pipefail

cd terraform

echo "=== Stage 1: Create infra & deploy apps via Terraform provisioners ==="
terraform init
terraform apply -auto-approve

echo
echo "=== Stage 2: Testing solution ==="
# Fetch frontend IP:
FR_IP=$(terraform output -raw frontend_public_ip)
echo "Frontend is live at: http://$FR_IP"

# Simple health‐check:
echo -n "curl result: "
curl -s http://$FR_IP | head -n1

# Save outputs to a file:
terraform output > ../terraform-outputs.txt

echo
echo "✅ Deployment complete. Outputs saved to terraform-outputs.txt"
