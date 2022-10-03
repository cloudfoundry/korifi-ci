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
    if [[ -d helm/kpack-image-builder ]]; then
      kbld \
        -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kpack-image-builder-kbld.yml" \
        -f "../korifi-ci/build/overlays/$CLUSTER_NAME/kpack-image-builder/values.yaml" \
        --images-annotation=false >"$tmp/values.yaml"
      helm upgrade --install kpack-image-builder helm/kpack-image-builder \
        --values "$tmp/values.yaml" \
        --wait
    else
      kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/kpack-image-builder" |
        kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kpack-image-builder-kbld.yml" -f- |
        kapp deploy -y -a korifi-kpack-image-builder -f-
    fi
  }
  popd
}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  deploy
}

main
