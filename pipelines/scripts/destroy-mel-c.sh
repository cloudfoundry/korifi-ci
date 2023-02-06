#!/bin/bash

set -euo pipefail

pushd cf-k8s-secrets/bosh-lite-cf/directors
{
  ./lite-me-up.sh destroy mel-c
}
popd
