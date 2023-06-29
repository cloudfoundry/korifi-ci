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

cd korifi

if [[ "$APP_PATH" == *dorifi ]]; then
  make build-dorifi
fi

cf api "$API_SERVER_ROOT" --skip-ssl-validation
cf auth gareth
cf create-org gareth
cf create-space -o gareth gareth
cf target -o gareth -s gareth

cf push "$(cat /proc/sys/kernel/random/uuid)" -p "$APP_PATH"
