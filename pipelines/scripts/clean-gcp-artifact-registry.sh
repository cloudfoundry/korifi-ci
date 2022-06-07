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
  gcloud artifacts packages list --repository=$KPACK_REPO_NAME --location=$KPACK_REPO_LOCATION --format=json |
    jq '.[]|.name' -r |
    xargs -IN gcloud artifacts packages delete N --repository=$KPACK_REPO_NAME --location=$KPACK_REPO_LOCATION
}

main
