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
      if gcloudx artifacts repositories list \
        --location "$KPACK_REPO_LOCATION" \
        --filter REPOSITORY:"$KPACK_REPO_NAME" |
        grep -q "$KPACK_REPO_NAME"; then

        gcloudx artifacts repositories delete "$KPACK_REPO_NAME" \
          --location "$KPACK_REPO_LOCATION" \
          --quiet
      fi
      gcloudx artifacts repositories create \
        "$KPACK_REPO_NAME" \
        --location "$KPACK_REPO_LOCATION" \
        --repository-format=docker \
        --quiet

      # delete all korifi images
      if gcloudx artifacts repositories list \
        --location "$CI_REPO_LOCATION" \
        --filter REPOSITORY:"$CI_REPO_NAME" |
        grep -q "$CI_REPO_NAME"; then
        gcloudx artifacts repositories delete "$CI_REPO_NAME" \
          --location "$CI_REPO_LOCATION" \
          --quiet
      fi
      gcloudx artifacts repositories create \
        "$CI_REPO_NAME" \
        --location "$CI_REPO_LOCATION" \
        --repository-format=docker \
        --quiet
      ;;

    "EKS")
      aws ecr describe-repositories \
        --region "$KPACK_REPO_LOCATION" |
        jq -r ".repositories[].repositoryName|select(.|startswith(\"$KPACK_REPO_NAME\"))" |
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
