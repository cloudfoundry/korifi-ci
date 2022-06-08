#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

gcloud() {
  $(which gcloud) --project=cf-on-k8s-wg $@
}

main() {
  gcloud-login

  export -f gcloud

  # delete all images produced by kpack during the tests
  gcloud artifacts packages list --repository=$KPACK_REPO_NAME --location=$KPACK_REPO_LOCATION --format=json --filter='name!~^kpack/beta$' |
    jq '.[]|.name' -r |
    sed 's|/|%2F|g' |
    xargs -IN gcloud artifacts packages delete N --quiet --repository=$KPACK_REPO_NAME --location=$KPACK_REPO_LOCATION --async
}

main
