#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export KUBECONFIG=$HOME/.kube/config
export-kubeconfig

case "$CLUSTER_TYPE" in
  "GKE")
    kubectl config set-credentials "$CRDS_TEST_CLI_USER" \
      --client-certificate=<(base64 -d <<<"$CRDS_TEST_CLI_CERT") \
      --client-key=<(base64 -d <<<"$CRDS_TEST_CLI_KEY") \
      --embed-certs
    ;;
  "EKS")
    kubectl config set-credentials "$CRDS_TEST_CLI_USER" \
      --token="$CRDS_TEST_CLI_USER_TOKEN"
    ;;

  *)
    echo "unknown 'CLUSTER_TYPE': $CLUSTER_TYPE"
    exit 1
    ;;
esac

cd korifi
go run github.com/onsi/ginkgo/v2/ginkgo ./tests/crds
