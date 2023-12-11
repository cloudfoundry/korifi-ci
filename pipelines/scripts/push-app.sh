#!/bin/bash

set -euo pipefail

if [[ "$CLUSTER_TYPE" != "GKE" ]]; then
  echo "Skipping - prepushing test apps is only needed on GKE to avoid the BLOB_UNKNOWN issue"
  exit 0
fi

source korifi-ci/pipelines/scripts/common/target.sh

orgName="$(basename "$APP_PATH")"
cf -v create-org "$orgName"
cf -v create-space -o "$orgName" gareth
cf -v target -o "$orgName" -s gareth

cf push "$(cat /proc/sys/kernel/random/uuid)" -p "$APP_PATH"
