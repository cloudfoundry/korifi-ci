#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
}

deploy() {
  pushd korifi
  {
    kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/job-task-runner" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-job-task-runner-kbld.yml" -f- | kapp deploy -y -a korifi-job-task-runner -f-
  }
  popd

}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  deploy
}

main
