#!/bin/bash

set -euo pipefail

export SKIP_DEPLOY=true
KUBECONFIG="$(realpath $KUBECONFIG)"

pushd korifi
{
  make test-e2e
}
popd
