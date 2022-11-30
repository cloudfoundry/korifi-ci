#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

main() {
  export KUBECONFIG=$PWD/kube.config
  export-kubeconfig "$CLUSTER_NAME"

  source ./korifi/scripts/account-creation.sh $PWD/korifi/scripts

  cat <<EOF >accounts/env_vars.yaml
E2E_USER_NAME: $E2E_USER_NAME
E2E_USER_PEM: $E2E_USER_PEM
E2E_SERVICE_ACCOUNT: $E2E_SERVICE_ACCOUNT
E2E_SERVICE_ACCOUNT_TOKEN: $E2E_SERVICE_ACCOUNT_TOKEN
CF_ADMIN_KEY: $CF_ADMIN_KEY
CF_ADMIN_CERT: $CF_ADMIN_CERT
EOF
}

main
