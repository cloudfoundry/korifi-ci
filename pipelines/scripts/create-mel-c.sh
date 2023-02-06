#!/bin/bash

set -euo pipefail

pushd cf-k8s-secrets/bosh-lite-cf/directors
{
  echo -n "Created: " >testing
  date >>testing
}
popd
