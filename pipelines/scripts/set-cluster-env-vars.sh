#!/bin/bash

set -euo pipefail

cat <<EOF >clusters/env_vars.yaml
TERRAFORM_SERVICE_ACCOUNT_JSON: $TERRAFORM_SERVICE_ACCOUNT_JSON
AWS_REGION: $AWS_REGION
AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
GCP_PROJECT_ID: $GCP_PROJECT_ID
GCP_ZONE: $GCP_ZONE
GCP_SERVICE_ACCOUNT_JSON: $GCP_SERVICE_ACCOUNT_JSON
CLUSTER_NAME: $CLUSTER_NAME
CLUSTER_TYPE: $CLUSTER_TYPE
NODE_MACHINE_TYPE: $NODE_MACHINE_TYPE
USE_LETSENCRYPT: ${USE_LETSENCRYPT:-}
KPACK_REPO_LOCATION: ${KPACK_REPO_LOCATION}
KPACK_REPO_NAME: ${KPACK_REPO_NAME}
CSR_SIGNING_DISALLOWED: ${CSR_SIGNING_DISALLOWED}
EOF
