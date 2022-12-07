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
  if [[ "$cluster_values" == "null" ]]; then
    echo "Cluster $CLUSTER_NAME does not exist"
    exit 0
  fi

  export-kubeconfig
  kubectl get service --all-namespaces |
    awk '/LoadBalancer/ { printf "kubectl delete service -n %s %s", $1, $2 }' |
    xargs -IN sh -c "N"

  if [[ "${CLUSTER_TYPE:-}" == "GKE" ]]; then
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
  fi

  terraform destroy \
    -var "name=$CLUSTER_NAME" \
    -var "node-count=$WORKER_COUNT" \
    -auto-approve
}
popd || exit 1
