#!/bin/bash

set -euo pipefail

source "korifi-ci/pipelines/scripts/common/git-functions.sh"

pushd korifi
{
  make vendir-update-dependencies
  create_pr "ci/bump-vendir" "Updating vendir dependencies"
}
popd
