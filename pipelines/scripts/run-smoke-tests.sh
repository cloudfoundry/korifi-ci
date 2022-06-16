#!/bin/bash

set -euo pipefail

KUBECONFIG="$(realpath "$KUBECONFIG")"

kubectl config set-credentials "${SMOKE_TEST_USER}" --client-certificate=<(base64 -d <<<"$CF_ADMIN_CERT") --client-key=<(base64 -d <<<"$CF_ADMIN_KEY") --embed-certs

cd korifi/tests/smoke
ginkgo
