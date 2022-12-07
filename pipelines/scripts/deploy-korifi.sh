#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

# refresh the kbld kubectl builder secret before the parallel builds kick in
docker_login() {
  kubectl delete secret buildkit &>/dev/null || true

  case "$CLUSTER_TYPE" in
    "GKE")
      kubectl create secret docker-registry buildkit --docker-server='europe-west1-docker.pkg.dev' \
        --docker-username=_json_key --docker-password="$REGISTRY_SERVICE_ACCOUNT_JSON"
      ;;

    "EKS")
      local ECR_ACCESS_KEY_ID ECR_SECRET_ACCESS_KEY ECR_TOKEN
      pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME"
      {
        terraform init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true
        ECR_ACCESS_KEY_ID="$(terraform output -raw code_pusher_key_id)"
        ECR_SECRET_ACCESS_KEY="$(terraform output -raw code_pusher_secret)"
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

  location=$(curl -i https://github.com/cloudfoundry/korifi/releases/latest | grep "location: " | tr -d '\r')
  version="${location##*tag/v}"

  helm upgrade --install korifi \
    "https://github.com/cloudfoundry/korifi/releases/download/v${version}/korifi-${version}.tgz" \
    --namespace korifi \
    --values "korifi-ci/build/values/$CLUSTER_NAME/values.yaml" \
    --wait

  if [[ -n "$USE_LETSENCRYPT" ]]; then
    clone_letsencrypt_cert "korifi-api-ingress-cert" "korifi"
    clone_letsencrypt_cert "korifi-workloads-ingress-cert" "korifi"
  fi
}

deploy() {
  pushd korifi
  {
    kbld \
      -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kbld.yml" \
      -f "../korifi-ci/build/values/image-values.yaml" \
      --images-annotation=false >"/tmp/values.yaml"

    helm dependency update helm/korifi

    helm upgrade --install korifi helm/korifi \
      --namespace korifi \
      --values "/tmp/values.yaml" \
      --values "../korifi-ci/build/values/$CLUSTER_NAME/values.yaml" \
      --wait

    if [[ -n "$USE_LETSENCRYPT" ]]; then
      clone_letsencrypt_cert "korifi-api-ingress-cert" "korifi"
      clone_letsencrypt_cert "korifi-workloads-ingress-cert" "korifi"
    fi
  }
  popd
}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  export-kubeconfig
  docker_login
  setup_root_namespace
  if [[ -n "$DEPLOY_LATEST_RELEASE" ]]; then
    deploy_latest_release
  else
    deploy
  fi
}

main
