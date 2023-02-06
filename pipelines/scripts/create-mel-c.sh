#!/bin/bash

set -euo pipefail

pushd cf-k8s-secrets/bosh-lite-cf/directors
{
  date >testing
  git add .
  git config user.name "Korifi Bot"
  git config user.email "cloudfoundry-korifi@groups.vmware.com"
  git commit -m "saving mel-c state"
}
popd
