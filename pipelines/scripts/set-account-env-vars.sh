#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export KUBECONFIG=$PWD/kube.config
export-kubeconfig

case "$CLUSTER_TYPE" in
  "EKS")

    echo "$TERRAFORM_SERVICE_ACCOUNT_JSON" >"/tmp/terraform-sa.json"
    OLD_GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"
    GOOGLE_APPLICATION_CREDENTIALS="/tmp/terraform-sa.json"

    terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true

    CF_ADMIN_KEY_ID="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_admin_key_id)"
    CF_ADMIN_SECRET="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_admin_secret)"
    CF_ADMIN_TOKEN="$(AWS_ACCESS_KEY_ID="$CF_ADMIN_KEY_ID" AWS_SECRET_ACCESS_KEY="$CF_ADMIN_SECRET" aws --region "$AWS_REGION" eks get-token --cluster-name "$CLUSTER_NAME")"

    CF_USER_KEY_ID="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_admin_key_id)"
    CF_USER_SECRET="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_admin_secret)"
    CF_USER_TOKEN="$(AWS_ACCESS_KEY_ID="$CF_USER_KEY_ID" AWS_SECRET_ACCESS_KEY="$CF_USER_SECRET" aws --region "$AWS_REGION" eks get-token --cluster-name "$CLUSTER_NAME")"

    # make account-creation.sh skip creating users
    export E2E_USER_NAME=cf-user
    export E2E_LONGCERT_USER_NAME=ignore
    export CF_ADMIN_CERT=ignore
    export E2E_USER_TOKEN="$CF_USER_TOKEN"
    export CF_ADMIN_TOKEN

    GOOGLE_APPLICATION_CREDENTIALS="$OLD_GOOGLE_APPLICATION_CREDENTIALS"
    ;;
esac

source ./korifi/scripts/account-creation.sh $PWD/korifi/scripts

cat <<EOF >accounts/env_vars.yaml
E2E_USER_NAME: $E2E_USER_NAME
E2E_USER_PEM: ${E2E_USER_PEM:-}
E2E_USER_TOKEN: ${E2E_USER_TOKEN:-}
E2E_SERVICE_ACCOUNT: $E2E_SERVICE_ACCOUNT
E2E_SERVICE_ACCOUNT_TOKEN: $E2E_SERVICE_ACCOUNT_TOKEN
CF_ADMIN_KEY: ${CF_ADMIN_KEY:-}
CF_ADMIN_CERT: ${CF_ADMIN_CERT:-}
CF_ADMIN_TOKEN: ${CF_ADMIN_TOKEN:-}
EOF
