#!/bin/bash

set -euo pipefail

KBLD_CONFIG_DIR="$PWD/korifi-ci/build/kbld/release"
COMMIT_SHA=$(cat korifi/.git/ref)
VERSION="dev-$(cat korifi-release-version/version)-$COMMIT_SHA"

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

publish_images() {
  pushd korifi
  {
    build-korifi-api >/dev/null
    build-korifi-controllers >/dev/null
    build-korifi-job-task-runner >/dev/null
    build-korifi-kpack-image-builder >/dev/null
    build-korifi-statefulset-runner >/dev/null

    echo "============================================================================="
    echo "  Dev images have been successfully published on dockerhub."
    echo "    commit sha:  $COMMIT_SHA"
    echo "    images tag:  $VERSION"
    echo "============================================================================="
  }
  popd
}

main() {
  generate_kube_config
  docker_login
  update_config_with_version
  publish_images
}

main
