#!/bin/bash

set -euo pipefail

echo "Deleting unattached EBS CSI volumes in EC2"
aws ec2 describe-volumes \
  --region eu-west-1 \
  --filter Name=tag:ebs.csi.aws.com/cluster,Values=true \
  --filter Name=status,Values=available |
  jq -r '.Volumes[].VolumeId' |
  xargs -IN aws ec2 delete-volume --region eu-west-1 --volume-id N
