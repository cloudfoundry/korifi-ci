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
      ECR_ACCESS_KEY_ID="$(terraform output -raw code_pusher_key_id)"
      ECR_SECRET_ACCESS_KEY="$(terraform output -raw code_pusher_secret)"
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

deploy() {
  pushd korifi
  {
    kbld \
      -f "../korifi-ci/build/kbld/$CLUSTER_NAME/korifi-kbld.yml" \
      -f "../korifi-ci/build/values/image-values.yaml" \
      --images-annotation=false >"/tmp/values.yaml"

    helm dependency update helm/korifi

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/enforce: restricted
  name: korifi
EOF

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

create_root_namespace() {
  cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/enforce: restricted
  name: cf
EOF

  kubectl delete secret -n cf image-registry-credentials --ignore-not-found
  kubectl create secret -n cf docker-registry image-registry-credentials \
    --docker-server="${DOCKER_SERVER}" \
    --docker-username="${DOCKER_USERNAME}" \
    --docker-password="${DOCKER_PASSWORD}"
}

main() {
  export KUBECONFIG=$PWD/kube/kube.config
  export-kubeconfig
  docker_login
  create_root_namespace
  deploy
}

main
