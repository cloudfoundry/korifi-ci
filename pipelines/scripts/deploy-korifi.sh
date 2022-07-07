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
    kubectl kustomize controllers/config/overlays/pr-e2e | kbld -f ../korifi-ci/pipelines/main/assets/pr/korifi-controllers-kbld.yml -f- | kapp deploy -y -a korifi-controllers -f-
    create_tls_secret "korifi-workloads-ingress-cert" "korifi-controllers-system" "*.$CLUSTER_NAME.korifi.cf-app.com"

    kubectl kustomize api/config/overlays/pr-e2e | kbld -f ../korifi-ci/pipelines/main/assets/pr/korifi-api-kbld.yml -f- | kapp deploy -y -a korifi-api -f-
    create_tls_secret "korifi-api-ingress-cert" "korifi-api-system" "*.$CLUSTER_NAME.korifi.cf-app.com"

    kubectl kustomize kpack-image-builder/config/overlays/pr-e2e | kbld -f ../korifi-ci/pipelines/main/assets/pr/korifi-kpack-image-builder-kbld.yml -f- | kapp deploy -y -a korifi-kpack-image-builder -f-

    kubectl kustomize statefulset-runner/config/default | kbld -f ../korifi-ci/pipelines/main/assets/pr/korifi-statefulset-runner-kbld.yml -f- | kapp deploy -y -a korifi-statefulset-runner -f-

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
