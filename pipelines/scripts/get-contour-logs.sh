#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  kubectl -n projectcontour logs deployments/contour --all-containers=true --since 20m
}

main
