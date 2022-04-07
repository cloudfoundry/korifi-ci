#!/bin/bash

set -euo pipefail

export SKIP_DEPLOY=true
KUBECONFIG="$(realpath $KUBECONFIG)"

pushd cf-k8s-controllers-pr
{
  make test-e2e
}
popd
