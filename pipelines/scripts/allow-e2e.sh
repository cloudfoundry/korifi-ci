#!/bin/bash

set -euo pipefail

API_URL=https://api.github.com
PR_NUMBER="$(<pr-label/.git/resource/pr)"
PR_AUTHOR="$(<pr-label/.git/resource/author)"

team="$(curl -su ${KORIFI_BOT_NAME}:${KORIFI_BOT_TOKEN} ${API_URL}/orgs/${GITHUB_ORG}/teams/${GITHUB_TEAM}/members | jq -r '.[].login')"

for user in $team; do
  if [[ "$user" == "${PR_AUTHOR}" ]] || [[ "${PR_AUTHOR}" == "dependabot[bot]" ]] || [[ "${PR_AUTHOR}" == "korifi-bot" ]]; then
    echo Allowing e2e run for trusted user "$user"
    # note that PR labels are updated using the issues endpoint
    curl -XPOST \
      --silent \
      -u ${KORIFI_BOT_NAME}:${KORIFI_BOT_TOKEN} \
      -H "Accept: application/vnd.github.v3+json" \
      ${API_URL}/repos/${GITHUB_ORG}/${GITHUB_REPO}/issues/${PR_NUMBER}/labels \
      -d '{"labels":["e2e-allowed"]}'
    break
  fi
done
