#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

gcloudx() {
  gcloud --project=${PROJECT} $@
}

main() {
  gcloud-login

  export -f gcloudx

  # delete all images produced by kpack during the tests - but not the kpack cluster-builder image
  gcloudx artifacts docker images list ${KPACK_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${KPACK_REPO_NAME} --format=json --filter="package!~/kpack/beta\$" |
    jq -r '.[]|.package + "@" + .version' |
    xargs -I {} bash -c 'gcloudx "$@"' _ artifacts docker images delete {} --async --quiet --delete-tags

  # delete tags of korifi images older than a day
  yesterday=$(date -d "yesterday" -Iseconds -u)
  for package in korifi-api korifi-controllers korifi-kpack-image-builder; do
    gcloudx artifacts docker images list ${CI_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${CI_REPO_NAME}/${package} --format=json --filter="createTime<${yesterday}" |
      jq -r '.[]|.package + "@" + .version' |
      xargs -I {} bash -c 'gcloudx "$@"' _ artifacts docker images delete {} --async --quiet --delete-tags
  done

  echo "################# REPOSITORY SIZES #################"
  gcloud artifacts repositories describe --location ${KPACK_REPO_LOCATION} ${KPACK_REPO_NAME}
  echo
  gcloud artifacts repositories describe --location ${CI_REPO_LOCATION} ${CI_REPO_NAME}
  echo "####################################################"
}

main
