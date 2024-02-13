#!/bin/bash

set -euo pipefail

source "korifi-ci/pipelines/scripts/common/git-functions.sh"

pushd korifi
{
  local branch="ci/bump-vendir"

  make vendir-update-dependencies
  create_pr "$branch" "Updating vendir dependencies"
}
popd
