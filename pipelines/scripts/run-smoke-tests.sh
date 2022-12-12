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
      --token="$CF_ADMIN_TOKEN"
    ;;

  *)
    echo "unknown 'CLUSTER_TYPE': $CLUSTER_TYPE"
    exit 1
    ;;
esac

echo "waiting for ClusterBuilder to be ready..."
kubectl wait --for=condition=ready clusterbuilder --all=true --timeout=15m

cd korifi
ginkgo ./tests/smoke
