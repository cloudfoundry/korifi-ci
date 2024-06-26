#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

if ! export-kubeconfig; then
  echo "Exiting since there is (probably) no cluster. Check error message above!"
  exit 0
fi

ELB_DNS_NAME=""

if ! kubectl get namespaces korifi-gateway; then
  echo "Exiting since there are no contour objects to clean up"
  exit 0
fi

if ! kubectl get -n korifi-gateway services envoy-korifi; then
  echo "Exiting since there is no contour envoy service"
  exit 0
fi

case "$CLUSTER_TYPE" in
  "EKS")
    ELB_DNS_NAME="$(kubectl get service envoy-korifi -n korifi-gateway -ojsonpath='{.status.loadBalancer.ingress[0].hostname}')"
    ;;

  "GKE")
    ELB_DNS_NAME="$(kubectl get service envoy-korifi -n korifi-gateway -ojsonpath='{.status.loadBalancer.ingress[0].ip}')"
    ;;

  *)
    echo "Invalid CLUSTER_TYPE: $CLUSTER_TYPE"
    echo "Valid values are: EKS, GKE"
    exit 1
    ;;
esac

pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME/dns"
{
  terraform init \
    -backend-config="prefix=terraform/state/${CLUSTER_NAME}-dns" \
    -upgrade=true

  terraform destroy \
    -var "cluster_name=$CLUSTER_NAME" \
    -var "elb_dns_name=$ELB_DNS_NAME" \
    -auto-approve
}
popd
