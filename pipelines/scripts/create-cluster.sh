#!/bin/bash

set -eu

echo "$GCP_SERVICE_ACCOUNT_JSON" >service-account.json
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/service-account.json"

TERRAFORM_CONFIG_PATH=cf-k8s-secrets/ci-deployment/gke-cluster/cluster-config

terraform -chdir="$TERRAFORM_CONFIG_PATH" init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true
terraform -chdir="$TERRAFORM_CONFIG_PATH" apply -var "name=$CLUSTER_NAME" \
  -var "node-count-per-zone=$WORKER_COUNT" \
  -var "release-channel=$RELEASE_CHANNEL" \
  -auto-approve
