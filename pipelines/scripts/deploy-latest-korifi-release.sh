#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/secrets.sh

tmp="$(mktemp -d)"
trap "rm -rf $tmp" EXIT

deploy() {
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
  name: korifi
EOF

  location=$(curl -i https://github.com/cloudfoundry/korifi/releases/latest | grep "location: ")
  version="${location##*tag/v}"

  helm upgrade --install korifi \
    "https://github.com/cloudfoundry/korifi/releases/download/v${version}/korifi-${version}.tgz" \
    --namespace korifi \
    --values "korifi-ci/build/values/$CLUSTER_NAME/values.yaml" \
    --wait

  if [[ -n "$USE_LETSENCRYPT" ]]; then
    clone_letsencrypt_cert "korifi-api-ingress-cert" "korifi"
    clone_letsencrypt_cert "korifi-workloads-ingress-cert" "korifi"
  fi
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
  create_root_namespace
  deploy
}

main
