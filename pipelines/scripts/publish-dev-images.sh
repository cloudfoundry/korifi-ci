#!/bin/bash

set -euo pipefail

KBLD_CONFIG_DIR="$PWD/korifi-ci/build/kbld/release"
COMMIT_SHA=$(cat korifi/.git/ref)
BUMPED_VERSION_CORE="$(awk -F. '/[0-9]+\./{$NF++;print}' OFS=. korifi-release-version/version)"
TIMESTAMP="$(date +%Y%m%d%H%M%S.%N)"
VERSION="v$BUMPED_VERSION_CORE-dev.$TIMESTAMP"
TAG="dev-$VERSION-$COMMIT_SHA"

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/kbld-korifi

update_config_with_version() {
  yq -i "with(.destinations[]; .tags=[\"$TAG\"])" "$KBLD_CONFIG_DIR/korifi-kbld.yml"
  yq -i "with(.sources[]; .kubectlBuildkit.build.rawOptions += [\"--build-arg\", \"version=$VERSION\"])" "$KBLD_CONFIG_DIR/korifi-kbld.yml"
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
  update_config_with_version
  publish_images
}

main
