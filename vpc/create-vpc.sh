#!/usr/bin/env bash
set -e

#— config —
KEY_PATH=~/.ssh/my-key.pem
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# 1) Create infra
echo "⏳ Stage-1: Creating infra..."
KEY_NAME=$(basename "$KEY_PATH" .pem)
export KEY_NAME
export AWS_REGION=eu-north-1
bash scripts/create_infra.sh

# grab the outputs:
pushd infra
  FRONTEND_IP=$(terraform output -raw frontend_public_ip)
  BACKEND_IP=$(terraform output -raw backend_private_ip)
popd
echo " ⇒ FRONTEND_IP=$FRONTEND_IP, BACKEND_IP=$BACKEND_IP"

# 2) Deploy apps
echo "⏳ Stage-2: Deploying frontend…"
ssh ${SSH_OPTS} -i ${KEY_PATH} ubuntu@${FRONTEND_IP} 'bash -s' < scripts/frontend.sh

echo "⏳ Stage-2: Deploying backend…"
ssh ${SSH_OPTS} -i ${KEY_PATH} ubuntu@${BACKEND_IP} 'bash -s' < scripts/backend.sh

# 3) Test
FRONTEND_URL="http://${FRONTEND_IP}:8080"
echo "⏳ Stage-3: Testing frontend at $FRONTEND_URL"
curl -f $FRONTEND_URL || { echo "🚨 frontend test failed"; exit 1; }

echo "✅ All stages completed successfully!"
