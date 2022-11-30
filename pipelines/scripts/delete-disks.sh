#!/bin/bash

set -euo pipefail

echo "$GCP_SERVICE_ACCOUNT_JSON" >"$PWD/service-account.json"
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/service-account.json"

# shellcheck disable=SC1091
source korifi-ci/pipelines/scripts/common/gcloud-functions

delete-disk() {
  local disk_name zone
  disk_name="$1"
  zone="$2"
  echo "Deleting disk: $disk_name in region: $zone"
  gcloud compute disks delete -q "$disk_name" --zone "$zone"
}

delete-disks-eks() {
  echo "Deleting unattached EBS CSI volumes in EC2"
  aws ec2 describe-volumes \
    --region "$AWS_REGION" \
    --filter Name=tag:ebs.csi.aws.com/cluster,Values=true \
    --filter Name=status,Values=available |
    jq -r '.Volumes[].VolumeId' |
    xargs -IN aws ec2 delete-volume --region "$AWS_REGION" --volume-id N
}

delete-disks-gke() {
  gcloud-login
  echo "Deleting leftover disks for cluster $CLUSTER_NAME"
  disks=$(gcloud compute disks list --filter="$CLUSTER_NAME" --format="csv[separator=' ',no-heading](name, location())")
  if [[ -z "$disks" ]]; then
    echo "Nothing to delete!"
    exit 0
  fi

  while IFS= read -r line; do
    local disk_name zone
    disk_name="$(echo "$line" | awk '{print $1}')"
    zone="$(echo "$line" | awk '{print $2}')"
    delete-disk "$disk_name" "$zone"
  done < <(echo "${disks}")
}

main() {
  case "$CLUSTER_TYPE" in
    "GKE")
      delete-disks-gke
      ;;
    "EKS")
      delete-disks-eks
      ;;
    *)
      echo "Invalid CLUSTER_TYPE: $CLUSTER_TYPE"
      echo "Valid values are: EKS, GKE"
      exit 1
      ;;
  esac
}

main
