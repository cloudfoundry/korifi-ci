#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export-kubeconfig

ELB_DNS_NAME=""

if ! kubectl get namespaces projectcontour; then
  echo "Exiting since there are no contour objects to clean up"
  exit 0
fi

case "$CLUSTER_TYPE" in
  "EKS")
    ELB_DNS_NAME="$(kubectl get service envoy -n projectcontour -ojsonpath='{.status.loadBalancer.ingress[0].hostname}')"
    ;;

  "GKE")
    ELB_DNS_NAME="$(kubectl get service envoy -n projectcontour -ojsonpath='{.status.loadBalancer.ingress[0].ip}')"
    ;;

  *)
    echo "Invalid CLUSTER_TYPE: $CLUSTER_TYPE"
    echo "Valid values are: EKS, GKE"
    exit 1
    ;;
esac

TERRAFORM_CONFIG_PATH=cf-k8s-secrets/ci-deployment/$CLUSTER_NAME/dns

terraform -chdir="$TERRAFORM_CONFIG_PATH" init \
  -backend-config="prefix=terraform/state/${CLUSTER_NAME}-dns" \
  -upgrade=true

terraform -chdir="$TERRAFORM_CONFIG_PATH" destroy \
  -var "cluster_name=$CLUSTER_NAME" \
  -var "elb_dns_name=$ELB_DNS_NAME" \
  -auto-approve
