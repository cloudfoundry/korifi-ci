#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
}

deploy() {
  pushd korifi
  {
    kbld \
      -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-statefulset-runner-kbld.yml" \
      -f "../korifi-ci/build/overlays/$CLUSTER_NAME/statefulset-runner/values.yaml" \
      --images-annotation=false >"$tmp/values.yaml"
    helm upgrade --install statefulset-runner helm/statefulset-runner \
      --values "$tmp/values.yaml" \
      --wait
  }
  popd

}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  deploy
}

main
