#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh

appName=dorifiii

if cf org --guid "$appName"; then
  echo "Long living org $appName already exists. Nothing to do."
  exit 0
fi

cf create-org "$appName"
cf create-space -o "$appName" "$appName"
cf target -o "$appName" -s "$appName"

cf push "$appName" -p dorifi --no-start
cf create-user-provided-service upsi -p '{"foo": "bar"}'
cf bind-service "$appName" upsi
cf start "$appName"
