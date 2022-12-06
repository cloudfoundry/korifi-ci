#!/bin/bash

set -euo pipefail

KUBECONFIG="$(realpath "$KUBECONFIG")"

case "$CLUSTER_TYPE" in
  "GKE")
    kubectl config set-credentials "$SMOKE_TEST_USER" \
      --client-certificate=<(base64 -d <<<"$CF_ADMIN_CERT") \
      --client-key=<(base64 -d <<<"$CF_ADMIN_KEY") \
      --embed-certs
    ;;
  "EKS")
    kubectl config set-credentials "$SMOKE_TEST_USER" \
      --token="$(base64 -d <<<"$CF_ADMIN_TOKEN")"
    ;;

  *)
    echo "unknown 'CLUSTER_TYPE': $CLUSTER_TYPE"
    exit 1
    ;;
esac

cd korifi
ginkgo ./tests/smoke
