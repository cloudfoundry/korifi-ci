#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

gcloudx() {
  gcloud --project="${PROJECT}" "$@"
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

      echo -n "recreating docker repository"
      for _ in {1..10}; do
        if gcloudx artifacts repositories create \
          "$KPACK_REPO_NAME" \
          --location "$KPACK_REPO_LOCATION" \
          --repository-format=docker \
          --quiet; then
          break
        fi
        echo -n .
        sleep 2
      done
      echo
      ;;

    "EKS")
      aws ecr describe-repositories \
        --region "$KPACK_REPO_LOCATION" |
        jq -r ".repositories[].repositoryName|select(.|startswith(\"$KPACK_REPO_NAME\"))" |
        parallel aws ecr delete-repository \
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
