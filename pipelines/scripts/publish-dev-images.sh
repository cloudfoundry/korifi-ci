#!/bin/bash

set -euo pipefail

KBLD_CONFIG_DIR="$PWD/korifi-ci/build/kbld/release"
COMMIT_SHA=$(cat korifi/.git/ref)

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/kbld-korifi

compute-version() {
  pushd korifi
  {
    VERSION=$(git describe --tags | awk -F'[.-]' '{$3++; print $1 "." $2 "." $3 "-" $4 "-" $5}')
  }
  popd

  TAG="dev-$VERSION-$COMMIT_SHA"
}

update_config_with_version() {
  yq -i "with(.sources[]; .kubectlBuildkit.build.rawOptions += [\"--build-arg\", \"version=$VERSION\"])" "$KBLD_CONFIG_DIR/korifi-kbld.yml"
  yq -i "with(.destinations[]; .tags=[\"$TAG\"])" "$KBLD_CONFIG_DIR/korifi-kbld.yml"
}

publish_images() {
  pushd korifi
  {
    build-korifi >/dev/null

    echo "============================================================================="
    echo "  Dev images have been successfully published on dockerhub."
    echo "    commit sha:     $COMMIT_SHA"
    echo "    images tag:     $TAG"
    echo "    Korifi version: $VERSION"
    echo "============================================================================="
  }
  popd
}

main() {
  export-kubeconfig
  docker_login
  compute-version
  update_config_with_version
  publish_images
}

main
