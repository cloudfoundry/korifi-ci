#!/bin/bash

set -euo pipefail

KBLD_CONFIG_DIR="$PWD/korifi-ci/build/kbld/release"
RELEASE_OUTPUT_DIR="$PWD/release-output"
VERSION=$(cat korifi-release-version/version)
RELEASE_ARTIFACTS_DIR="$RELEASE_OUTPUT_DIR/korifi-$VERSION"

mkdir -p "$RELEASE_ARTIFACTS_DIR"

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/kbld-korifi

configure_kbld() {
  yq -i "with(.destinations[]; .tags=[\"latest\", \"$VERSION\"])" "$KBLD_CONFIG_DIR/korifi-kbld.yml"
  yq -i "with(.sources[]; .kubectlBuildkit.build.rawOptions += [\"--build-arg\", \"version=v$VERSION\"])" "$KBLD_CONFIG_DIR/korifi-kbld.yml"

  yq -i "with(.sources[]; .kubectlBuildkit.build.rawOptions += [\"--build-arg\", \"HELM_CHART_SOURCE=$RELEASE_ARTIFACTS_DIR\"])" "$KBLD_CONFIG_DIR/korifi-installer-kbld.yml"
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

    kbld -f "$KBLD_CONFIG_DIR/korifi-installer-kbld.yml" \
      -f "scripts/installer/install-korifi-kind.yaml" \
      >"$RELEASE_OUTPUT_DIR/install-korifi-kind.yaml"
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
  configure_kbld
  create_release
}

main
