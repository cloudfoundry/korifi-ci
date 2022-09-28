#!/bin/bash

set -euo pipefail

function pr_exists_for_branch {
  curl \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/cloudfoundry/korifi/pulls?head=cloudfoundry:$1" |
    grep "cloudfoundry:$1"
}

function create_pr_for_branch {
  curl \
    -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/cloudfoundry/korifi/pulls \
    --data '{"title":"Updating vendir dependencies","body":"Generated from korifi CI","head":"'"$1"'","base":"main"}'
}

cd korifi
make vendir-update-dependencies

if [[ ! $(git status --porcelain) ]]; then
  echo "All vendir dependencies already up to date"
  exit 0
fi

branch="ci/bump-vendir"
git switch -C "$branch"
git add .
git config user.email "cloudfoundry-korifi@groups.vmware.com"
git config user.name "Korifi-Bot"
git commit -m 'Updating vendir dependencies'
git push -f "https://$GITHUB_TOKEN@github.com/cloudfoundry/korifi.git" "$branch"

if ! pr_exists_for_branch "$branch"; then
  create_pr_for_branch "$branch"
fi
