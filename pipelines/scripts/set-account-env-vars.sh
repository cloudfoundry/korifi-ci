#!/bin/bash

set -euo pipefail

source cf-k8s-ci/pipelines/scripts/common/gcloud-functions

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

  source ./cf-k8s-controllers-pr/scripts/account-creation.sh $PWD/cf-k8s-controllers-pr/scripts

  cat <<EOF >accounts/env_vars.yaml
E2E_USER_NAMES: $E2E_USER_NAMES
E2E_USER_PEMS: $E2E_USER_PEMS
E2E_SERVICE_ACCOUNTS: $E2E_SERVICE_ACCOUNTS
E2E_SERVICE_ACCOUNT_TOKENS: $E2E_SERVICE_ACCOUNT_TOKENS
CF_ADMIN_KEY: $CF_ADMIN_KEY
CF_ADMIN_CERT: $CF_ADMIN_CERT
EOF
}

main
