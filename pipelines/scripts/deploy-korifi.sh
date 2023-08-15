#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/secrets.sh

BUILD_KUBECONFIG=$PWD/kube/build.config
# refresh the kbld kubectl builder secret before the parallel builds kick in
registry_login() {

  case "$CLUSTER_TYPE" in
    "GKE")
      kubectl delete secret gar-buildkit &>/dev/null || true
      kubectl create secret docker-registry gar-buildkit --docker-server='europe-docker.pkg.dev' \
        --docker-username=_json_key --docker-password="$REGISTRY_SERVICE_ACCOUNT_JSON"
      ;;

    "EKS")
      kubectl delete secret ecr-buildkit &>/dev/null || true
      local ECR_TOKEN
      ECR_TOKEN="$(AWS_ACCESS_KEY_ID="$ECR_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$ECR_SECRET_ACCESS_KEY" aws ecr get-login-password --region "$AWS_REGION")"
      kubectl create secret docker-registry ecr-buildkit --docker-server='007801690126.dkr.ecr.eu-west-1.amazonaws.com' \
        --docker-username=AWS --docker-password="$ECR_TOKEN"
      ;;

    *)
      echo "Invalid CLUSTER_TYPE: $CLUSTER_TYPE"
      echo "Valid values are: EKS, GKE"
      exit 1
      ;;
  esac
}

get_eks_terraform_vars() {
  ECR_ACCESS_ROLE_ARN=
  ECR_ACCESS_KEY_ID=
  ECR_SECRET_ACCESS_KEY=

  if [[ "$CLUSTER_TYPE" == "EKS" ]]; then
    pushd "cf-k8s-secrets/ci-deployment/$CLUSTER_NAME"
    {
      terraform init -backend-config="prefix=terraform/state/$CLUSTER_NAME" -upgrade=true
      ECR_ACCESS_KEY_ID="$(terraform output -raw code_pusher_key_id)"
      ECR_SECRET_ACCESS_KEY="$(terraform output -raw code_pusher_secret)"
      ECR_ACCESS_ROLE_ARN="$(terraform output -raw ecr_access_role_arn)"
    }
    popd
  fi
}

undefault_existing_storage_class() {
  if [[ "$CLUSTER_TYPE" == "EKS" ]]; then
    kubectl annotate storageclasses gp2 --overwrite "storageclass.kubernetes.io/is-default-class"="false" || true
  fi
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
  KBLD_CONFIG_FILE="$PWD/korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kbld.yml"
  VALUES_FILE="$PWD/korifi-ci/build/values/image-values.yaml"

  pushd korifi
  {
    VERSION=$(git describe --tags | awk -F'[.-]' '{$3++; print $1 "." $2 "." $3 "-" $4 "-" $5}')
    yq -i "with(.sources[]; .kubectlBuildkit.build.rawOptions += [\"--build-arg\", \"version=$VERSION\"])" "$KBLD_CONFIG_FILE"
    KUBECONFIG="$BUILD_KUBECONFIG" kbld \
      -f "$KBLD_CONFIG_FILE" \
      -f "$VALUES_FILE" \
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
    extra_helm_flags+=("--set" "eksContainerRegistryRoleARN=$ECR_ACCESS_ROLE_ARN")
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
  export KUBECONFIG=$PWD/kube/kube.config
  export KUBE_CONFIG_PATH="$KUBECONFIG"
  export-kubeconfig
  undefault_existing_storage_class
  setup_root_namespace
  get_eks_terraform_vars
  if [[ -n "$DEPLOY_LATEST_RELEASE" ]]; then
    deploy_latest_release
  else
    KUBECONFIG="$BUILD_KUBECONFIG" CLUSTER_NAME="$BUILD_CLUSTER_NAME" CLUSTER_TYPE="$BUILD_CLUSTER_TYPE" export-kubeconfig
    KUBECONFIG="$BUILD_KUBECONFIG" registry_login
    deploy_local
  fi
}

main
