#!/bin/bash

set -euo pipefail

echo "$GCP_SERVICE_ACCOUNT_JSON" >service-account.json
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/service-account.json"

TERRAFORM_CONFIG_PATH=cf-k8s-secrets/ci-deployment/$CLUSTER_NAME

terraform -chdir="$TERRAFORM_CONFIG_PATH" init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true
terraform -chdir="$TERRAFORM_CONFIG_PATH" output $PROPERTY >terraform-output/result
