#!/bin/bash

set -euo pipefail

source cf-k8s-ci/pipelines/scripts/common/gcloud-functions
source cf-k8s-ci/pipelines/scripts/common/secrets.sh

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
  pushd cf-k8s-controllers-pr
  {
    kubectl kustomize controllers/config/overlays/pr-e2e | kbld -f scripts/assets/cf-k8s-controllers-kbld.yml -f- | kapp deploy -y -a cf-k8s-controllers -f-
    create_tls_secret "cf-k8s-workloads-ingress-cert" "cf-k8s-controllers-system" "*.$CLUSTER_NAME.cf-k8s.cf"

    kubectl kustomize api/config/overlays/pr-e2e | kbld -f scripts/assets/cf-k8s-api-kbld.yml -f- | kapp deploy -y -a cf-k8s-api -f-
    create_tls_secret "cf-k8s-api-ingress-cert" "cf-k8s-api-system" "*.$CLUSTER_NAME.cf-k8s.cf"

    sed 's/vcap\.me/'$CLUSTER_NAME.cf-k8s.cf'/' controllers/config/samples/cfdomain.yaml | kubectl apply -f-
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
