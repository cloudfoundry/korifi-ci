#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

BUILD_KUBECONFIG=$PWD/kube/build.config
ECR_ACCESS_ROLE_ARN=
# refresh the kbld kubectl builder secret before the parallel builds kick in
docker_login() {
  kubectl delete secret buildkit &>/dev/null || true

  case "$CLUSTER_TYPE" in
    "GKE")
      kubectl create secret docker-registry buildkit --docker-server='europe-docker.pkg.dev' \
        --docker-username=_json_key --docker-password="$REGISTRY_SERVICE_ACCOUNT_JSON"
      ;;

    "EKS")
      local ECR_ACCESS_KEY_ID ECR_SECRET_ACCESS_KEY ECR_TOKEN
      pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME"
      {
        terraform init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true
        ECR_ACCESS_KEY_ID="$(terraform output -raw code_pusher_key_id)"
        ECR_SECRET_ACCESS_KEY="$(terraform output -raw code_pusher_secret)"
        ECR_ACCESS_ROLE_ARN="$(terraform output -raw ecr_access_role_arn)"
      }
      popd
      ECR_TOKEN="$(AWS_ACCESS_KEY_ID="$ECR_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$ECR_SECRET_ACCESS_KEY" aws ecr get-login-password --region "$AWS_REGION")"
      kubectl create secret docker-registry buildkit --docker-server='007801690126.dkr.ecr.eu-west-1.amazonaws.com' \
        --docker-username=AWS --docker-password="$ECR_TOKEN"
      ;;

    *)
      echo "Invalid CLUSTER_TYPE: $CLUSTER_TYPE"
      echo "Valid values are: EKS, GKE"
      exit 1
      ;;
  esac
}

setup_root_namespace() {
  pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME/k8s"
  {
    terraform init \
      -backend-config="prefix=terraform/state/$CLUSTER_NAME-k8s" \
      -upgrade=true
    terraform apply \
      -var "name=$CLUSTER_NAME" \
      -var "registry-server=${DOCKER_SERVER}" \
      -var "registry-username=${DOCKER_USERNAME}" \
      -var "registry-password=${DOCKER_PASSWORD}" \
      -auto-approve
  }
  popd
}
deploy_latest_release() {
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
  name: korifi
EOF

  local location
  location=$(curl -i https://github.com/cloudfoundry/korifi/releases/latest | grep "location: " | tr -d '\r')
  local version="${location##*tag/v}"

  deploy "https://github.com/cloudfoundry/korifi/releases/download/v${version}/korifi-${version}.tgz"
}

deploy_local() {
  pushd korifi
  {
    KUBECONFIG="$BUILD_KUBECONFIG" kbld \
      -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kbld.yml" \
      -f "../korifi-ci/build/values/image-values.yaml" \
      --images-annotation=false >"/tmp/values.yaml"
  }
  popd

  helm dependency update korifi/helm/korifi
  deploy "korifi/helm/korifi" "/tmp/values.yaml"
}

deploy() {
  local chart="$1"
  local extra_values_file="${2:-}"

  local extra_helm_flags=()
  if [[ -n "$extra_values_file" ]]; then
    extra_helm_flags+=("--values" "$extra_values_file")
  fi
  if [[ -n "$ECR_ACCESS_ROLE_ARN" ]]; then
    extra_helm_flags+=("--set" "global.eksContainerRegistryRoleARN=$ECR_ACCESS_ROLE_ARN")
  fi

  helm upgrade --install korifi "$chart" \
    --namespace korifi \
    --values "korifi-ci/build/values/$CLUSTER_NAME/values.yaml" \
    "${extra_helm_flags[@]}" \
    --wait

  if [[ -n "$USE_LETSENCRYPT" ]]; then
    clone_letsencrypt_cert "korifi-api-ingress-cert" "korifi"
    clone_letsencrypt_cert "korifi-workloads-ingress-cert" "korifi"
  fi
}

main() {
  KUBECONFIG="$BUILD_KUBECONFIG" CLUSTER_NAME="$BUILD_CLUSTER_NAME" CLUSTER_TYPE="$BUILD_CLUSTER_TYPE" export-kubeconfig
  export KUBECONFIG=$PWD/kube/kube.config
  export-kubeconfig
  docker_login
  setup_root_namespace
  if [[ -n "$DEPLOY_LATEST_RELEASE" ]]; then
    deploy_latest_release
  else
    deploy_local
  fi
}

main
