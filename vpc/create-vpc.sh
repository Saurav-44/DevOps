#!/usr/bin/env bash
set -e

pushd infra
  terraform init
  terraform apply -auto-approve \
    -var="key_name=${KEY_NAME:-k-pair}" \
    -var="region=${AWS_REGION:-eu-north-1}"
popd
