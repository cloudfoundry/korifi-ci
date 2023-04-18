#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export-kubeconfig

kubectl config set-credentials cf-admin \
  --client-certificate=<(base64 -d <<<"$CF_ADMIN_CERT") \
  --client-key=<(base64 -d <<<"$CF_ADMIN_KEY") \
  --embed-certs

cf api "$CF_API_URL"
echo cf-admin | cf login
cf create-org postfacto
cf create-space -o postfacto postfacto
cf target -o postfacto -s postfacto

cf push -f postfacto/manifest.yml \
  -p postfacto \
  --var domain="${CLUSTER_NAME}.korifi.cf-app.com" \
  --var postgres-address="$POSTGRES_ADDRESS" \
  --var postgres-user="$POSTGRES_USER" \
  --var postgres-password="$POSTGRES_PASSWORD" \
  --var secret-key-base="$SECRET_KEY_BASE"

cf run-task postfacto -c "ADMIN_EMAIL=$ADMIN_EMAIL ADMIN_PASSWORD=$ADMIN_PASSWORD bundle exec rake admin:create_user"
