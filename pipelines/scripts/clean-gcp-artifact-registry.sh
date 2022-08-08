#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

gcloudx() {
  gcloud --project=${PROJECT} "$@"
}

main() {
  gcloud-login

  export -f gcloudx

  # delete all images produced by kpack during the tests - but not the kpack cluster-builder image
  gcloudx artifacts docker images list ${KPACK_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${KPACK_REPO_NAME} --format=json --filter="package!~/kpack/beta\$" |
    jq -r '.[]|.package' |
    xargs -I {} bash -c 'gcloudx "$@"' _ artifacts docker images delete {} --async --quiet

  # delete all but latest kpack cluster-builder image
  latest=$(gcloudx artifacts docker images list ${KPACK_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${KPACK_REPO_NAME}/kpack/beta --sort-by='~create_time' --format=json --limit=1 |
    jq -r '.[] | .version')

  gcloudx artifacts docker images list ${KPACK_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${KPACK_REPO_NAME}/kpack/beta --filter="version!~${latest}" --format=json |
    jq -r '.[] | .package + "@" + .version' |
    xargs -I {} bash -c 'gcloudx "$@"' _ artifacts docker images delete {} --async --quiet --delete-tags

  # delete versions of korifi images older than a day
  yesterday=$(date -d "yesterday" -Iseconds -u)
  for package in korifi-api korifi-controllers korifi-job-task-runner korifi-kpack-image-builder korifi-statefulset-runner; do
    gcloudx artifacts docker images list ${CI_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${CI_REPO_NAME}/${package} --format=json --filter="createTime<${yesterday}" |
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
