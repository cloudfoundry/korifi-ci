#!/bin/bash

set -euo pipefail

echo "$GCP_SERVICE_ACCOUNT_JSON" >"$PWD/service-account.json"
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/service-account.json"

# shellcheck disable=SC1091
source korifi-ci/pipelines/scripts/common/gcloud-functions

pushd cf-k8s-secrets/ci-deployment/$CLUSTER_NAME || exit 1
{
  terraform init \
    -backend-config="prefix=terraform/state/$CLUSTER_NAME"

  cluster_values="$(terraform show -json | jq -r '.values ')"
  if [ "$cluster_values" == "null" ]; then
    echo "Cluster $CLUSTER_NAME does not exist"
    exit 0
  fi

  case "${CLUSTER_TYPE:-}" in
    "GKE")
      cluster_network="$(terraform show -json | jq -r '.values.root_module.resources[] | select(.name == "network") | .values.name')"
      if [[ -n "$cluster_network" ]]; then
        gcloud-login

        # Firewall rules are created when a LoadBalancer Service is created in GCP,
        # and since terraform doesn't know about them, they have to be manually deleted.
        # See https://github.com/terraform-providers/terraform-provider-google/issues/5948
        firewall_rules=$(gcloud compute firewall-rules list --filter=network="$cluster_network" --format="value(name)")
        for rule_name in $firewall_rules; do
          gcloud compute firewall-rules delete "$rule_name" --quiet || echo "firewall rule $rule_name not found"
        done

        # Network endpoint groups are created for the rapid chanel version of Kubernetes
        # clusters on GCP (couldn't find a docs link). Since terraform doesn't know about
        # these resources they also must be deleted separately.
        network_endpoint_groups_csv=$(gcloud beta compute network-endpoint-groups list --filter="network ~ $CLUSTER_NAME" --format="csv[no-heading](name,zone)")
        for name_zone in $network_endpoint_groups_csv; do
          name="$(echo "$name_zone" | awk -F ',' '{ print $1 }')"
          zone="$(echo "$name_zone" | awk -F ',' '{ print $2 }')"
          gcloud beta compute network-endpoint-groups delete --zone "$zone" "$name" --quiet
        done
      fi
      ;;

    "EKS")
      export-kubeconfig

      # if kubectl get namespaces projectcontour; then
      #   cat <<EOF >"contour-elb.tf"
      # resource "aws_elb" "contour" {
      # listener {
      # instance_port     = 8000
      # instance_protocol = "http"
      # lb_port           = 80
      # lb_protocol       = "http"
      # }
      # availability_zones = ["x"]
      # }

      # resource "aws_security_group" "elb" {
      # }
      # EOF

      #   ELB_NAME="$(
      #     aws elb describe-load-balancers --region "$AWS_REGION" |
      #       jq -r '.LoadBalancerDescriptions[0].LoadBalancerName'
      #   )"
      #   terraform import aws_elb.contour "$ELB_NAME"
      #   terraform import aws_security_group.elb \
      #     "$(
      #       aws elb describe-load-balancers \
      #         --region "$AWS_REGION" \
      #         --load-balancer-name "$ELB_NAME" |
      #         jq -r '.LoadBalancerDescriptions[0].SecurityGroups[0]'
      #     )"
      # fi
      ;;
  esac

  terraform destroy \
    -var "name=$CLUSTER_NAME" \
    -var "node-count=$WORKER_COUNT" \
    -auto-approve
}
popd || exit 1
