#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh

cf create-org pairup || true
cf create-space -o pairup pairup || true
cf target -o pairup -s pairup

pushd pairup
{
  echo "$FIREBASE_CONF" >src/conf.js

  yarn install
  yarn build

  cf push pairup

  # once we can do fancy domain names...
  # cf push pairup --no-start
  # cf share-private-domain pairup eirini.cf
  # cf map-route pairup eirini.cf --hostname pairup
  # cf start pairup
}
popd
