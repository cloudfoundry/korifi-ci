#!/bin/bash

set -euo pipefail

if curl -fSsLko /dev/null --connect-timeout 2 https://api.mel-c.korifi.cf-app.com; then
  echo "mel-c CF already exists"
  exit 0
fi

pushd cf-k8s-secrets/bosh-lite-cf/directors
{
  ./lite-me-up.sh create mel-c
}
popd
