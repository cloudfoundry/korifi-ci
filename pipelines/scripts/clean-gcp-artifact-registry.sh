#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

gcloudx() {
  gcloud --project=${PROJECT} "$@"
}

main() {
  gcloud-login

  export -f gcloudx

  # delete all images produced by kpack during the tests
  gcloudx artifacts docker images list ${KPACK_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${KPACK_REPO_NAME} --format=json |
    jq -r '.[]|.package' |
    xargs -I {} bash -c 'gcloudx "$@"' _ artifacts docker images delete {} --async --quiet

  # delete all korifi images
  for package in korifi-api korifi-controllers korifi-job-task-runner korifi-kpack-image-builder korifi-statefulset-runner; do
    gcloudx artifacts docker images list ${CI_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${CI_REPO_NAME}/${package} --format=json |
      jq -r '.[]|.package + "@" + .version' |
      xargs -I {} bash -c 'gcloudx "$@"' _ artifacts docker images delete {} --async --quiet --delete-tags
  done

  echo
  echo "################# REPOSITORY SIZES #################"
  gcloud artifacts repositories describe --location ${KPACK_REPO_LOCATION} ${KPACK_REPO_NAME}
  echo
  gcloud artifacts repositories describe --location ${CI_REPO_LOCATION} ${CI_REPO_NAME}
  echo "####################################################"
}

main
