#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  export-kubeconfig "$CLUSTER_NAME"
  kubectl -n projectcontour get pods -l app=envoy --no-headers -o custom-columns=":metadata.name" | xargs -I {} kubectl -n projectcontour logs --since 30m {} envoy
}

main
