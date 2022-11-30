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
