#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export KUBECONFIG=$PWD/kube.config
export-kubeconfig

cf api "$API_SERVER_ROOT" --skip-ssl-validation

if [[ "$CLUSTER_TYPE" == "EKS" ]]; then
  echo "$TERRAFORM_SERVICE_ACCOUNT_JSON" >"/tmp/terraform-sa.json"
  OLD_GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"
  GOOGLE_APPLICATION_CREDENTIALS="/tmp/terraform-sa.json"

  pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME"
  {
    terraform init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true

    CF_ADMIN_KEY_ID="$(terraform output -raw cf_admin_key_id)"
    CF_ADMIN_SECRET="$(terraform output -raw cf_admin_secret)"
    CF_ADMIN_ARN="$(terraform output -raw cf_admin_arn)"
    CF_ADMIN_TOKEN="$(AWS_ACCESS_KEY_ID="$CF_ADMIN_KEY_ID" AWS_SECRET_ACCESS_KEY="$CF_ADMIN_SECRET" aws --region "$AWS_REGION" eks get-token --cluster-name "$CLUSTER_NAME" | jq -r '.status.token')"
  }
  popd

  GOOGLE_APPLICATION_CREDENTIALS="$OLD_GOOGLE_APPLICATION_CREDENTIALS"

  kubectl patch \
    -n kube-system \
    configmaps/aws-auth \
    --type merge \
    -p '{"data":{"mapUsers":"- userarn: '"$CF_ADMIN_ARN"'\n  username: cf-admin"}}'

  kubectl config set-credentials "cf-admin" --token="$CF_ADMIN_TOKEN"
else
  korifi/scripts/create-new-user.sh cf-admin
fi

echo cf-admin | cf login
