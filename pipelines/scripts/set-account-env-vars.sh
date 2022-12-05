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
    CF_ADMIN_ARN="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_admin_arn)"
    CF_ADMIN_TOKEN="$(AWS_ACCESS_KEY_ID="$CF_ADMIN_KEY_ID" AWS_SECRET_ACCESS_KEY="$CF_ADMIN_SECRET" aws --region "$AWS_REGION" eks get-token --cluster-name "$CLUSTER_NAME" | jq -r '.token')"

    CF_USER_KEY_ID="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_user_key_id)"
    CF_USER_SECRET="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_user_secret)"
    CF_USER_ARN="$(terraform -chdir="cf-k8s-secrets/ci-deployment/$CLUSTER_NAME" output -raw cf_user_arn)"
    CF_USER_TOKEN="$(AWS_ACCESS_KEY_ID="$CF_USER_KEY_ID" AWS_SECRET_ACCESS_KEY="$CF_USER_SECRET" aws --region "$AWS_REGION" eks get-token --cluster-name "$CLUSTER_NAME" | jq -r '.token')"

    # make account-creation.sh skip creating users
    export E2E_USER_NAME=cf-user
    export E2E_LONGCERT_USER_NAME=ignore
    export CF_ADMIN_CERT=ignore
    export E2E_USER_TOKEN="$CF_USER_TOKEN"
    export CF_ADMIN_TOKEN

    GOOGLE_APPLICATION_CREDENTIALS="$OLD_GOOGLE_APPLICATION_CREDENTIALS"

    kubectl patch \
      -n kube-system \
      configmaps/aws-auth \
      --type merge \
      -p '{"data":{"mapUsers":"- userarn: '"$CF_USER_ARN"'\n  username: cf-user\n- userarn: '"$CF_ADMIN_ARN"'\n  username: cf-admin"}}'
    ;;
esac

source ./korifi/scripts/account-creation.sh $PWD/korifi/scripts

cat <<EOF >accounts/env_vars.yaml
CF_ADMIN_PEM: ${CF_ADMIN_PEM:-}
CF_ADMIN_TOKEN: ${CF_ADMIN_TOKEN:-}
CLUSTER_VERSION_MAJOR: $CLUSTER_VERSION_MAJOR
CLUSTER_VERSION_MINOR: $CLUSTER_VERSION_MINOR
E2E_LONGCERT_USER_NAME: $E2E_LONGCERT_USER_NAME
E2E_LONGCERT_USER_PEM: ${E2E_LONGCERT_USER_PEM:-}
E2E_SERVICE_ACCOUNT: $E2E_SERVICE_ACCOUNT
E2E_SERVICE_ACCOUNT_TOKEN: $E2E_SERVICE_ACCOUNT_TOKEN
E2E_USER_NAME: $E2E_USER_NAME
E2E_USER_PEM: ${E2E_USER_PEM:-}
E2E_USER_TOKEN: ${E2E_USER_TOKEN:-}
EOF
