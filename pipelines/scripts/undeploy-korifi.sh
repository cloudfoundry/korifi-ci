#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

undeploy_cf() {
  kubectl delete secret --ignore-not-found=true -n korifi korifi-workloads-ingress-cert
  kubectl delete secret --ignore-not-found=true -n korifi korifi-api-ingress-cert

  kubectl delete namespace cf --ignore-not-found

  if helm status --namespace korifi korifi; then
    helm delete --namespace korifi korifi --wait
  fi
}

main() {
  export KUBECONFIG=$PWD/kube.config
  export-kubeconfig "$CLUSTER_NAME"
  undeploy_cf
}

main
