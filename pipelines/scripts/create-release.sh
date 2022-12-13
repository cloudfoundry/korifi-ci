#!/bin/bash

set -euo pipefail

KBLD_CONFIG_DIR="$PWD/korifi-ci/build/kbld/release"
RELEASE_OUTPUT_DIR="$PWD/release-output"
VERSION=$(cat korifi-release-version/version)
RELEASE_ARTIFACTS_DIR="$RELEASE_OUTPUT_DIR/korifi-$VERSION"

mkdir -p "$RELEASE_ARTIFACTS_DIR"

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/kbld-korifi

update_config_with_version() {
  yq -i "with(.destinations[]; .tags=[\"latest\", \"$VERSION\"])" "$KBLD_CONFIG_DIR/korifi-kbld.yml"
}

create_release() {
  pushd korifi
  {
    helm dependency update helm/korifi
    cp -a helm/korifi/* "$RELEASE_ARTIFACTS_DIR"
    export VALUES_BASE=helm/korifi
    build-korifi >"$RELEASE_ARTIFACTS_DIR/values.yaml"
    cp INSTALL.md "$RELEASE_ARTIFACTS_DIR"
    cp INSTALL.EKS.md "$RELEASE_ARTIFACTS_DIR"
    cp INSTALL.kind.md "$RELEASE_ARTIFACTS_DIR"
    cp README.helm.md "$RELEASE_ARTIFACTS_DIR"
  }
  popd

  pushd "$RELEASE_OUTPUT_DIR"
  {
    tar czf "korifi-$VERSION.tgz" "korifi-$VERSION"
  }
  popd
}

main() {
  export-kubeconfig
  docker_login
  update_config_with_version
  create_release
}

main
