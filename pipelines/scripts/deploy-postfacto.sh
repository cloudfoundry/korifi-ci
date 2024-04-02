#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh

cf create-org postfacto
cf create-space -o postfacto postfacto
cf target -o postfacto -s postfacto

cf push -f postfacto/manifest.yml \
  -p postfacto \
  --memory "512M" \
  --var domain="${CLUSTER_NAME}.korifi.cf-app.com" \
  --var postgres-address="$POSTGRES_ADDRESS" \
  --var postgres-user="$POSTGRES_USER" \
  --var postgres-password="$POSTGRES_PASSWORD" \
  --var secret-key-base="$SECRET_KEY_BASE"

cf run-task postfacto -c "ADMIN_EMAIL=$ADMIN_EMAIL ADMIN_PASSWORD=$ADMIN_PASSWORD bundle exec rake admin:create_user"
