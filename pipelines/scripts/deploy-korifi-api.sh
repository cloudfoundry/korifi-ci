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
    if [[ -d helm/api ]]; then
      kbld \
        -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-api-kbld.yml" \
        -f "../korifi-ci/build/overlays/$CLUSTER_NAME/api/values.yaml" \
        --images-annotation=false >"$tmp/values.yaml"
      helm update --install api helm/api \
        --values "$tmp/values.yaml" \
        --wait
    else
      kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/api" |
        kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-api-kbld.yml" -f- |
        kapp deploy -y -a korifi-api -f-
    fi

    if [[ -n "$USE_LETSENCRYPT" ]]; then
      clone_letsencrypt_cert "korifi-api-ingress-cert" "korifi-api-system"
    else
      create_tls_secret "korifi-api-ingress-cert" "korifi-api-system" "*.$CLUSTER_NAME.korifi.cf-app.com"
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
