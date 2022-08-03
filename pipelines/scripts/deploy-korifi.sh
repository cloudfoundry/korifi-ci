#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

docker_login() {
  kubectl delete secret buildkit &>/dev/null || true
  kubectl create secret docker-registry buildkit --docker-server='europe-west1-docker.pkg.dev' \
    --docker-username=_json_key --docker-password="$REGISTRY_SERVICE_ACCOUNT_JSON"
}

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
}

deploy_cf() {
  pushd korifi
  {
    kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/controllers" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-controllers-kbld.yml" -f- | kapp deploy -y -a korifi-controllers -f-
    if [[ -n "$USE_LETSENCRYPT" ]]; then
      clone_letsencrypt_cert "korifi-workloads-ingress-cert" "korifi-controllers-system"
    else
      create_tls_secret "korifi-workloads-ingress-cert" "korifi-controllers-system" "*.$CLUSTER_NAME.korifi.cf-app.com"
    fi

    kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/api" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-api-kbld.yml" -f- | kapp deploy -y -a korifi-api -f-
    if [[ -n "$USE_LETSENCRYPT" ]]; then
      clone_letsencrypt_cert "korifi-api-ingress-cert" "korifi-api-system"
    else
      create_tls_secret "korifi-api-ingress-cert" "korifi-api-system" "*.$CLUSTER_NAME.korifi.cf-app.com"
    fi

    kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/kpack-image-builder" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kpack-image-builder-kbld.yml" -f- | kapp deploy -y -a korifi-kpack-image-builder -f-

    kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/statefulset-runner" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-statefulset-runner-kbld.yml" -f- | kapp deploy -y -a korifi-statefulset-runner -f-

    kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/job-task-runner" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-job-task-runner-kbld.yml" -f- | kapp deploy -y -a korifi-job-task-runner -f-

    sed 's/vcap\.me/'$CLUSTER_NAME.korifi.cf-app.com'/' controllers/config/samples/cfdomain.yaml | kubectl apply -f-
  }
  popd

}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  docker_login
  deploy_cf
}

main
