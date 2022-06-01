#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KBLD_CONFIG_DIR="$PWD/korifi-ci/pipelines/main/assets/release"
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
  kubectl create secret docker-registry buildkit --docker-server="https://$REGISTRY_HOSTNAME/v1/" \
    --docker-username="$REGISTRY_USER" --docker-password="$REGISTRY_PASSWORD"

  export KBLD_REGISTRY_HOSTNAME="$REGISTRY_HOSTNAME"
  export KBLD_REGISTRY_USERNAME="$REGISTRY_USER"
  export KBLD_REGISTRY_PASSWORD="$REGISTRY_PASSWORD"
}

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
}

update_config_with_version() {
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-api-kbld.yml"
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-controllers-kbld.yml"
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-kpack-image-builder-kbld.yml"
}

create_release() {
  pushd korifi
  {
    kubectl kustomize api/config/base | kbld -f "$KBLD_CONFIG_DIR/korifi-api-kbld.yml" -f- >"$RELEASE_ARTIFACTS_DIR/korifi-api.yml"
    kubectl kustomize controllers/config/default | kbld -f "$KBLD_CONFIG_DIR/korifi-controllers-kbld.yml" -f- >"$RELEASE_ARTIFACTS_DIR/korifi-controllers.yml"
    kubectl kustomize kpack-image-builder/config/default | kbld -f "$KBLD_CONFIG_DIR/korifi-kpack-image-builder-kbld.yml" -f- >"$RELEASE_ARTIFACTS_DIR/korifi-kpack-image-builder.yml"
    cp -R dependencies "$RELEASE_ARTIFACTS_DIR"
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
  update_config_with_version
  create_release
}

main
