#!/bin/bash
#
pr_exists() {
  local branch="$1"

  curl \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/cloudfoundry/korifi/pulls?head=cloudfoundry:$branch" |
    grep "cloudfoundry:$branch"
}

create_pr() {
  local branch message
  branch="$1"
  message="$2"

  if [[ ! $(git status --porcelain) ]]; then
    echo "Nothing to PR."
    return
  fi

  commit "$branch" "$message"

  if pr_exists "$branch"; then
    echo "PR already exists for branch '$branch'"
    return
  fi

  curl \
    -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/cloudfoundry/korifi/pulls \
    --data '{"title":"Updating vendir dependencies","body":"Generated from korifi CI","head":"'"$1"'","base":"main"}'
}

commit() {
  local branch message
  branch="$1"
  message="$2"

  git switch -C "$branch"
  git add .
  git config user.email "cloudfoundry-korifi@groups.vmware.com"
  git config user.name "Korifi-Bot"
  git commit -m "$2"
  git push -f "https://$GITHUB_TOKEN@github.com/cloudfoundry/korifi.git" "$branch"
}
