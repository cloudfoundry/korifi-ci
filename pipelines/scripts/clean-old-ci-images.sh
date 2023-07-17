#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

gcloudx() {
  gcloud --project=${PROJECT} "$@"
}

main() {
  gcloud-login

  export -f gcloudx

  # retain latest and those created within the hour
  ts=$(date -d "12 hours ago" -Iseconds -u)
  latest=$(gcloudx artifacts docker images list ${CI_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${CI_REPO_NAME}/${PACKAGE} --sort-by='~create_time' --format=json --limit=1 |
    jq -r '.[] | .version')

  gcloudx artifacts docker images list ${CI_REPO_LOCATION}-docker.pkg.dev/${PROJECT}/${CI_REPO_NAME}/${PACKAGE} --filter="createTime<${ts} AND version!~${latest}" --format=json |
    jq -r '.[] | .package + "@" + .version' |
    xargs -I {} bash -c 'gcloudx "$@"' _ artifacts docker images delete {} --async --quiet --delete-tags

  echo "################# REPOSITORY SIZE #################"
  gcloud artifacts repositories describe --location ${CI_REPO_LOCATION} ${CI_REPO_NAME}
  echo "###################################################"
}

main
