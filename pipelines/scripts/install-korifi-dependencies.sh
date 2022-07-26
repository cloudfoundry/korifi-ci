#!/bin/bash

set -euo pipefail

# shellcheck disable=SC1091
source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

echo "$GCP_SERVICE_ACCOUNT_JSON" >"$PWD/service-account.json"
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/service-account.json"

gcloud-login
export-kubeconfig "$CLUSTER_NAME"

ip_addr="$(<terraform-output/result)"
pushd korifi
{
  ./scripts/install-dependencies.sh
  if [[ -n "$USE_LETSENCRYPT" ]]; then
    ensure_letsencrypt_issuer
    ensure_domain_wildcard_cert
  fi
  kubectl patch service envoy -n projectcontour -p "{\"spec\": { \"loadBalancerIP\": $ip_addr }}"

}
popd

if [[ "$USE_PATCHED_KPACK" == "true" ]]; then
  kubectl apply -f korifi-ci/build/patched-kpack.yml
fi
