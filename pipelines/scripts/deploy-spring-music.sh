#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh

cf delete-org -f spring-music

cf create-org spring-music
cf create-space -o spring-music spring-music
cf target -o spring-music -s spring-music

cf push -f spring-music/manifest.yml \
  -p spring-music \
  --no-start

db_uri="postgres://$DB_USERNAME:$DB_PASSWORD@$DB_ADDR:5432/spring-music"
cf create-user-provided-service spring-music-database -p "{\"uri\": \"${db_uri}\"}"
cf bind-service spring-music spring-music-database

cf start spring-music
