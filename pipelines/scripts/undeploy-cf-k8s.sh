#!/bin/bash

set -euo pipefail

source cf-k8s-ci/pipelines/scripts/common/gcloud-functions

generate_kube_config() {
  gcloud-login
  export-kubeconfig "$CLUSTER_NAME"
}

undeploy_cf() {
  tmp="$(mktemp -d)"
  trap "rm -rf $tmp" EXIT

  echo $GCP_SERVICE_ACCOUNT_JSON >"$tmp/sa.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$tmp/sa.json"

  kubectl delete subnamespaceanchor --ignore-not-found=true -n cf --all=true
  kubectl delete secret --ignore-not-found=true -n cf-k8s-controllers-system cf-k8s-workloads-ingress-cert
  kubectl delete secret --ignore-not-found=true -n cf-k8s-api-system cf-k8s-api-ingress-cert
  kapp delete -y -a cf-k8s-controllers
  kapp delete -y -a cf-k8s-api
}

main() {
  export KUBECONFIG=$PWD/kube.config
  generate_kube_config
  undeploy_cf
}

main
