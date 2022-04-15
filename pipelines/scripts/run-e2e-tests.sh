#!/bin/bash

set -euo pipefail

export SKIP_DEPLOY=true
KUBECONFIG="$(realpath $KUBECONFIG)"

pushd korifi-pr
{
  make test-e2e
}
popd
