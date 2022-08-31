#!/bin/bash

set -euo pipefail

cd korifi/tests

vendir sync

if [[ ! $(git status --porcelain) ]]; then
  echo "All vendir dependencies already up to date"
  exit 0
fi

branch="bump-vendir-$(date +%s)"
git checkout -b "$branch"
git add .
git config user.email "cloudfoundry-korifi@groups.vmware.com"
git config user.name "Korifi-Bot"
git commit -m 'Updating vendir dependencies'
git push "https://$GITHUB_TOKEN@github.com/cloudfoundry/korifi.git" "$branch"

curl \
  -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/cloudfoundry/korifi/pulls \
  --data '{"title":"Updating vendir dependencies","body":"Generated from korifi CI","head":"'"$branch"'","base":"main"}'
