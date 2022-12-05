#!/bin/bash

set -euo pipefail

# shellcheck disable=SC1091
source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

export-kubeconfig

pushd korifi
{
  ./scripts/install-dependencies.sh
  if [[ -n "$USE_LETSENCRYPT" ]]; then
    ensure_letsencrypt_issuer
    ensure_domain_wildcard_cert
  fi
}
popd

if [[ "$CLUSTER_TYPE" == "EKS" ]]; then
  terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true
  ROLE_ARN="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw ecr_access_role_arn)"
  kubectl annotate serviceaccount -n kpack controller "eks.amazonaws.com/role-arn=$ROLE_ARN"
fi
