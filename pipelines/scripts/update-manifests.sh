#!/bin/bash

set -euo pipefail

source "korifi-ci/pipelines/scripts/common/git-functions.sh"

pushd korifi
{
  local branch="ci/update-manifests"

  make generate manifests
  create_pr "$branch" "Updating kubebuilder manifests"
}
popd
