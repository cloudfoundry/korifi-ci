#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

# refresh the kbld kubectl builder secret before the parallel builds kick in
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

deploy() {
  pushd korifi
  {
    kubectl kustomize "../korifi-ci/build/overlays/$CLUSTER_NAME/controllers" | kbld -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-controllers-kbld.yml" -f- | kapp deploy -y -a korifi-controllers -f-
    if [[ -n "$USE_LETSENCRYPT" ]]; then
      clone_letsencrypt_cert "korifi-workloads-ingress-cert" "korifi-controllers-system"
    else
      create_tls_secret "korifi-workloads-ingress-cert" "korifi-controllers-system" "*.$CLUSTER_NAME.korifi.cf-app.com"
    fi

    sed 's/vcap\.me/'$CLUSTER_NAME.korifi.cf-app.com'/' controllers/config/samples/cfdomain.yaml | kubectl apply -f-
  }
  popd

}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  docker_login
  deploy
}

main