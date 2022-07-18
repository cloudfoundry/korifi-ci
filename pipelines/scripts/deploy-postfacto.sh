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
cat <<EOF >postfacto/package/assets/client/config.js
window.Retro = {
  config: {
    "globalNamespace": "Retro",
    "title": "Postfacto",
    "scripts": ["application.js"],
    "stylesheets": ["application.css"],
    "useRevManifest": true,
    "api_base_url": "/api",
    "websocket_url": "/cable",
    "websocket_port": 443,
    "enable_analytics": false,
    "contact": "",
    "terms": "",
    "privacy": ""
  }
}
EOF

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

sed -i "34i gem 'mini_racer'" postfacto/package/assets/Gemfile
sed -i "329i \ \ x86_64-linux" postfacto/package/assets/Gemfile.lock
sed -i "s/ruby '2.7.3'/ruby '2.7.5'/" postfacto/package/assets/Gemfile

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
