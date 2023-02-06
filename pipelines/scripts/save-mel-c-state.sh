#!/bin/bash

set -euo pipefail

pushd cf-k8s-secrets/bosh-lite-cf/directors
{
  git add .
  git config user.name "Korifi Bot"
  git config user.email "cloudfoundry-korifi@groups.vmware.com"
  git commit -m "$MESSAGE"
}
popd
