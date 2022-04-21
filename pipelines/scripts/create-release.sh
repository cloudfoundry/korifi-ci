#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KBLD_CONFIG_DIR="$PWD/korifi-ci/pipelines/release/assets"
RELEASE_OUTPUT_DIR="$PWD/release-output"
VERSION=$(cat korifi-release-version/version)
RELEASE_ARTIFACTS_DIR="$RELEASE_OUTPUT_DIR/korifi-$VERSION"

mkdir -p "$RELEASE_ARTIFACTS_DIR"

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

source korifi-ci/pipelines/scripts/common/gcloud-functions

docker_login() {
  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
  kubectl delete secret buildkit &>/dev/null || true
  kubectl create secret docker-registry buildkit --docker-server='https://index.docker.io/v1/' \
    --docker-username="$REGISTRY_USER" --docker-password="$REGISTRY_PASSWORD"
}

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
}

create_release() {
  pushd korifi
  {
    kubectl kustomize api/config/overlays/kind-local-registry | kbld -f "$KBLD_CONFIG_DIR/korifi-api-kbld.yml" -f- >"$RELEASE_ARTIFACTS_DIR/korifi-api.yml"
    kubectl kustomize controllers/config/overlays/kind-local-registry | kbld -f "$KBLD_CONFIG_DIR/korifi-controllers-kbld.yml" -f- >"$RELEASE_ARTIFACTS_DIR/korifi-controllers.yml"
  }
  popd

  pushd $RELEASE_OUTPUT_DIR
  {
    tar czf "korifi-$VERSION.tgz" "korifi-$VERSION"
  }
  popd
}

main() {
  generate_kube_config
  docker_login
  create_release
}

main
