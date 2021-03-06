#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

gcloud-login
export-kubeconfig "$CLUSTER_NAME"

kubectl config set-credentials cf-admin \
  --client-certificate=<(base64 -d <<<"$CF_ADMIN_CERT") \
  --client-key=<(base64 -d <<<"$CF_ADMIN_KEY") \
  --embed-certs

cf api "$CF_API_URL"
echo cf-admin | cf login
cf create-org postfacto
cf create-space -o postfacto postfacto
cf target -o postfacto -s postfacto

unzip postfacto/package.zip -d postfacto/
cp postfacto/package/tas/config/config.js postfacto/package/assets/client/

cat <<EOF >manifest.yml
applications:
- name: postfacto
  disk_quota: 1G
  instances: 2
  memory: 1G
  command: 'sh -c "bundle exec rake db:migrate && bundle exec rails s -p \$PORT -e \$RAILS_ENV"'
  env:
    WEBSOCKET_PORT: 443
    SESSION_TIME: 60
    DATABASE_URL: postgres://((postgres-user)):((postgres-password))@((postgres-address)):5432/postfacto
    SECRET_KEY_BASE: ((secret-key-base))
    ACTION_CABLE_HOST: postfacto.((domain))
    USE_POSTGRES_FOR_ACTION_CABLE: true
EOF

cat <<EOF >>postfacto/package/assets/config/database.yml

production:
  adapter: postgresql
  encoding: unicode
  database: postfacto
  pool: 5
EOF

sed -i "34i gem 'mini_racer'" postfacto/package/assets/Gemfile
sed -i "s/ruby '2.7.3'/ruby '2.7.5'/" postfacto/package/assets/Gemfile
sed -i "328i \ \ x86_64-linux" postfacto/package/assets/Gemfile.lock

cf push -f manifest.yml \
  -p postfacto/package/assets \
  --var api-app-name=postfacto-api \
  --var pcf-url="cf.${CLUSTER_NAME}.korifi.cf-app.com" \
  --var domain="${CLUSTER_NAME}.korifi.cf-app.com" \
  --var namespace=postfacto \
  --var postgres-address="$POSTGRES_ADDRESS" \
  --var postgres-user="$POSTGRES_USER" \
  --var postgres-password="$POSTGRES_PASSWORD" \
  --var secret-key-base="$SECRET_KEY_BASE"
