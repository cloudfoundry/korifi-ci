#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KBLD_CONFIG_DIR="$PWD/cf-k8s-ci/pipelines/release/assets"
RELEASE_OUTPUT_DIR="$PWD/release-output"
VERSION=$(cat korifi-version/version)
RELEASE_ARTIFACTS_DIR="$RELEASE_OUTPUT_DIR/korifi-$VERSION"

mkdir -p "$RELEASE_ARTIFACTS_DIR"

source cf-k8s-ci/pipelines/scripts/common/gcloud-functions
source cf-k8s-ci/pipelines/scripts/common/secrets.sh

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

docker_login() {
  kubectl delete secret buildkit &>/dev/null || true
  kubectl create secret docker-registry buildkit --docker-server='europe-west1-docker.pkg.dev' \
    --docker-username=_json_key --docker-password="$REGISTRY_SERVICE_ACCOUNT_JSON"
}

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
}

create_release() {
  pushd cf-k8s-controllers
  {
    kubectl kustomize api/config/overlays/pr-e2e | kbld -f "$KBLD_CONFIG_DIR/cf-k8s-api-kbld.yml" -f "$RELEASE_ARTIFACTS_DIR/korifi-api.yml"
    kubectl kustomize controllers/config/overlays/pr-e2e | kbld -f "$KBLD_CONFIG_DIR/cf-k8s-controllers-kbld.yml" -f "$RELEASE_ARTIFACTS_DIR/korifi-controllers.yml"
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
