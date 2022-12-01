#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export-kubeconfig

ELB_DNS_NAME=""

if ! kubectl get namespaces projectcontour; then
  # no contour == nothing to clean up
  exit 0
fi

TERRAFORM_CONFIG_PATH=cf-k8s-secrets/ci-deployment/$CLUSTER_NAME/dns

terraform -chdir="$TERRAFORM_CONFIG_PATH" init \
  -backend-config="prefix=terraform/state/${CLUSTER_NAME}-dns" \
  -upgrade=true

case "$CLUSTER_TYPE" in
  "EKS")
    ELB_DNS_NAME="$(kubectl get service envoy -n projectcontour -ojsonpath='{.status.loadBalancer.ingress[0].hostname}')"

    if [[ "${CLUSTER_TYPE:-}" == "EKS" ]]; then
      cat <<EOF >contour-elb.tf
resource "aws_elb" "contour" {
  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  availability_zones = ["x"]
}

resource "aws_security_group" "elb" {
}
EOF

      ELB_NAME="$(aws elb describe-load-balancers --region "$AWS_REGION" | jq -r '.LoadBalancerDescriptions[0].LoadBalancerName')"
      terraform -chdir="$TERRAFORM_CONFIG_PATH" import aws_elb.contour "$ELB_NAME"
      terraform -chdir="$TERRAFORM_CONFIG_PATH" import aws_security_group.elb \
        "$(
          aws elb describe-load-balancers \
            --region "$AWS_REGION" \
            --load-balancer-name "$ELB_NAME" |
            jq -r '.LoadBalancerDescriptions[0].SecurityGroups[0]'
        )"
    fi
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

terraform -chdir="$TERRAFORM_CONFIG_PATH" destroy \
  -var "cluster_name=$CLUSTER_NAME" \
  -var "elb_dns_name=$ELB_DNS_NAME" \
  -auto-approve
