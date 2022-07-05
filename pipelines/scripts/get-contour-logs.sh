#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  kubectl -n projectcontour logs deployments/contour --all-containers=true --since 20m
}

main
