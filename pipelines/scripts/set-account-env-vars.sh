#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
}

main() {
  tmp="$(mktemp -d)"
  trap "rm -rf $tmp" EXIT

  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
  export KUBECONFIG=$PWD/kube.config

  generate_kube_config

  source ./korifi-pr/scripts/account-creation.sh $PWD/korifi-pr/scripts

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
