#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

cleanup_root_namespace() {
  pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME/k8s"
  {
    terraform init \
      -backend-config="prefix=terraform/state/$CLUSTER_NAME-k8s" \
      -upgrade=true
    terraform destroy \
      -target kubernetes_namespace.cf \
      -var "name=$CLUSTER_NAME" \
      -var "registry-server=whatever" \
      -var "registry-username=whatever" \
      -var "registry-password=whatever" \
      -auto-approve
  }
  popd
}

undeploy_cf() {
  if helm status --namespace korifi korifi; then
    helm delete --namespace korifi korifi --wait
  fi
}

cleanup_korifi_namespace() {
  pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME/k8s"
  {
    terraform init \
      -backend-config="prefix=terraform/state/$CLUSTER_NAME-k8s" \
      -upgrade=true
    terraform destroy \
      -target kubernetes_namespace.korifi \
      -var "name=$CLUSTER_NAME" \
      -var "registry-server=whatever" \
      -var "registry-username=whatever" \
      -var "registry-password=whatever" \
      -auto-approve
  }
  popd
}

main() {
  export KUBECONFIG=$PWD/kube.config
  export KUBE_CONFIG_PATH="$KUBECONFIG"
  if ! export-kubeconfig; then
    echo "cannot export kubeconfig. Assuming no cluster (check error above). Exiting 0"
    exit 0
  fi
  cleanup_root_namespace
  undeploy_cf
  cleanup_korifi_namespace
}

main
