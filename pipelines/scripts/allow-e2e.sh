#!/bin/bash

set -eu

PR_NUMBER=$(<pr-label/.git/resource/pr)
PR_AUTHOR=$(<pr-label/.git/resource/author)

gh auth login --with-token <<<$KORIFI_BOT_TOKEN

team=$(gh repo view cloudfoundry/korifi --json assignableUsers --jq '.assignableUsers[].login')

for user in $team; do
  if [[ "$user" == "$PR_AUTHOR" ]]; then
    echo Allowing e2e run for team member "$user"
    gh pr --repo cloudfoundry/korifi edit $PR_NUMBER --add-label "e2e-allowed"
  fi
done
