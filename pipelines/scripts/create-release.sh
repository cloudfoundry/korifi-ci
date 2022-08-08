#!/bin/bash

set -euo pipefail

KBLD_CONFIG_DIR="$PWD/korifi-ci/build/kbld/release"
RELEASE_OUTPUT_DIR="$PWD/release-output"
VERSION=$(cat korifi-release-version/version)
RELEASE_ARTIFACTS_DIR="$RELEASE_OUTPUT_DIR/korifi-$VERSION"

mkdir -p "$RELEASE_ARTIFACTS_DIR"

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/kbld-korifi

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
}

update_config_with_version() {
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-api-kbld.yml"
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-controllers-kbld.yml"
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-job-task-runner-kbld.yml"
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-kpack-image-builder-kbld.yml"
  yq -i ".destinations[0].tags=[\"$VERSION\"]" "$KBLD_CONFIG_DIR/korifi-statefulset-runner-kbld.yml"
}

create_release() {
  pushd korifi
  {
    build-korifi-api >"$RELEASE_ARTIFACTS_DIR/korifi-api.yml"
    build-korifi-controllers >"$RELEASE_ARTIFACTS_DIR/korifi-controllers.yml"
    build-korifi-job-task-runner >"$RELEASE_ARTIFACTS_DIR/korifi-job-task-runner.yml"
    build-korifi-kpack-image-builder >"$RELEASE_ARTIFACTS_DIR/korifi-kpack-image-builder.yml"
    build-korifi-statefulset-runner >"$RELEASE_ARTIFACTS_DIR/korifi-statefulset-runner.yml"
    cp -R dependencies "$RELEASE_ARTIFACTS_DIR"
    cp INSTALL.md "$RELEASE_ARTIFACTS_DIR"
  }
  popd

  pushd "$RELEASE_OUTPUT_DIR"
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
