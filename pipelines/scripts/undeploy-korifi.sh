#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
}

undeploy_cf() {
  tmp="$(mktemp -d)"
  trap "rm -rf $tmp" EXIT

  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"

  kubectl delete secret --ignore-not-found=true -n korifi korifi-workloads-ingress-cert
  kubectl delete secret --ignore-not-found=true -n korifi korifi-api-ingress-cert

  kubectl delete namespace cf --ignore-not-found

  if helm status --namespace korifi korifi; then
    helm delete --namespace korifi korifi --wait
  fi
}

main() {
  export KUBECONFIG=$PWD/kube.config
  generate_kube_config
  undeploy_cf
}

main
