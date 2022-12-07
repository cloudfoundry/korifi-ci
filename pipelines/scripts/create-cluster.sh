#!/bin/bash

set -eu

echo "$GCP_SERVICE_ACCOUNT_JSON" >service-account.json
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/service-account.json"

TERRAFORM_CONFIG_PATH=cf-k8s-secrets/ci-deployment/$CLUSTER_NAME
RELEASE_CHANNEL_VAR=()

if [[ -n "${RELEASE_CHANNEL:-}" ]]; then
  RELEASE_CHANNEL_VAR=("-var" "release-channel=$RELEASE_CHANNEL")
fi

pushd "$TERRAFORM_CONFIG_PATH"
{
  terraform init \
    -backend-config="prefix=terraform/state/$CLUSTER_NAME" \
    -upgrade=true
  terraform apply \
    -var "name=$CLUSTER_NAME" \
    -var "node-count=$WORKER_COUNT" \
    "${RELEASE_CHANNEL_VAR[@]}" \
    -var "node-machine-type=$NODE_MACHINE_TYPE" \
    -auto-approve
}
popd
