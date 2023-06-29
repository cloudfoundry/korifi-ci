#!/bin/bash

set -euo pipefail

KUBECONFIG="$(realpath "$KUBECONFIG")"

case "$CLUSTER_TYPE" in
  "GKE")
    kubectl config set-credentials "gareth" \
      --client-certificate=<(base64 -d <<<"$CF_ADMIN_CERT") \
      --client-key=<(base64 -d <<<"$CF_ADMIN_KEY") \
      --embed-certs
    ;;

  *)
    echo "Skipping - only valid on GKE"
    exit 0
    ;;
esac

if [[ "$APP_PATH" == *dorifi ]]; then
  pushd korifi
  {
    make build-dorifi
  }
  popd
fi

cf api "$API_SERVER_ROOT" --skip-ssl-validation
cf auth gareth

orgName="$(basename "$APP_PATH")"
cf create-org "$orgName"
cf create-space -o "$orgName" gareth
cf target -o "$orgName" -s gareth

cf push "$(cat /proc/sys/kernel/random/uuid)" -p "$APP_PATH"
