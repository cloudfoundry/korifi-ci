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

  kubectl delete subnamespaceanchor --ignore-not-found=true -n cf --all=true || true # HNC is about to be removed, so this will fail
  kubectl delete secret --ignore-not-found=true -n korifi-controllers-system korifi-workloads-ingress-cert
  kubectl delete secret --ignore-not-found=true -n korifi-api-system korifi-api-ingress-cert
  kapp delete -y -a korifi-job-task-runner
  kapp delete -y -a korifi-statefulset-runner
  kapp delete -y -a korifi-kpack-image-builder
  kapp delete -y -a korifi-controllers
  kapp delete -y -a korifi-api
}

main() {
  export KUBECONFIG=$PWD/kube.config
  generate_kube_config
  undeploy_cf
}

main
