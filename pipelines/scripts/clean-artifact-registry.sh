#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

gcloudx() {
  gcloud --project=${PROJECT} "$@"
}

main() {
  case "$CLUSTER_TYPE" in
    "GKE")
      gcloud-login

      export -f gcloudx

      # delete all images produced by kpack during the tests
      gcloudx artifacts repositories delete "$KPACK_REPO_NAME" \
        --location "$KPACK_REPO_LOCATION" \
        --quiet
      gcloudx artifacts repositories create \
        "$KPACK_REPO_NAME" \
        --location "$KPACK_REPO_LOCATION" \
        --repository-format=docker \
        --quiet

      # delete all korifi images
      gcloudx artifacts repositories delete "$CI_REPO_NAME" \
        --location "$CI_REPO_LOCATION" \
        --quiet
      gcloudx artifacts repositories create \
        "$CI_REPO_NAME" \
        --location "$CI_REPO_LOCATION" \
        --repository-format=docker \
        --quiet
      ;;

    "EKS")
      aws ecr describe-repositories \
        --region "$KPACK_REPO_LOCATION" |
        jq -r '.repositories[].repositoryName' |
        grep "^$KPACK_REPO_NAME" |
        xargs -I{} aws ecr delete-repository \
          --repository-name {} \
          --force \
          --region "$KPACK_REPO_LOCATION" \
          --no-cli-pager
      ;;

    *)
      echo "CLUSTER_TYPE not recognised: $CLUSTER_TYPE"
      exit 1
      ;;

  esac

}

main
