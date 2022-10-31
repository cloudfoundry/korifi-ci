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
  echo "$GCP_SERVICE_ACCOUNT_JSON" >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"
}

deploy() {
  pushd korifi
  {
    kbld \
      -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kbld.yml" \
      -f "../korifi-ci/build/values/$CLUSTER_NAME/image-values.yaml" \
      --images-annotation=false >"$tmp/values.yaml"

    helm dependency update helm/korifi

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
  name: korifi
EOF

    helm upgrade --install korifi helm/korifi \
      --namespace korifi \
      --values "$tmp/values.yaml" \
      --values "../korifi-ci/build/values/$CLUSTER_NAME/values.yaml" \
      --wait

    if [[ -n "$USE_LETSENCRYPT" ]]; then
      clone_letsencrypt_cert "korifi-api-ingress-cert" "korifi"
      clone_letsencrypt_cert "korifi-workloads-ingress-cert" "korifi"
    fi
  }
  popd
}

create_root_namespace() {
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/enforce: restricted
  name: cf
EOF

  kubectl delete secret -n cf image-registry-credentials --ignore-not-found
  kubectl create secret -n cf docker-registry image-registry-credentials \
    --docker-server="${DOCKER_SERVER}" \
    --docker-username="${DOCKER_USERNAME}" \
    --docker-password="${DOCKER_PASSWORD}"
}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  generate_kube_config
  docker_login
  create_root_namespace
  deploy
}

main
