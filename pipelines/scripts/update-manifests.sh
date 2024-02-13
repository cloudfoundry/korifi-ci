#!/bin/bash

set -euo pipefail

source "korifi-ci/pipelines/scripts/common/git-functions.sh"

pushd korifi
{
  make generate manifests
  create_pr "ci/update-manifests" "Updating kubebuilder manifests"
}
popd
