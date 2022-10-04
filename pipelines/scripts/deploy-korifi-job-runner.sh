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
    if [[ -d helm/statefulset-runner ]]; then
      kbld \
        -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-job-task-runner-kbld.yml" \
        -f "../korifi-ci/build/overlays/$CLUSTER_NAME/job-task-runner/values.yaml" \
        --images-annotation=false >"$tmp/values.yaml"
      helm upgrade --install job-task-runner helm/job-task-runner \
        --values "$tmp/values.yaml" \
        --wait
    else
      kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/job-task-runner" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-job-task-runner-kbld.yml" -f- | kapp deploy -y -a korifi-job-task-runner -f-
    fi
  }
  popd

}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  deploy
}

main
