#!/bin/bash

# This is a temporary workaround to address the following issue with the Jammy stack and Rails apps.
# Once the Ruby buildpack fixes this we can remove this step from our pipeline.
# https://github.com/paketo-buildpacks/ruby/issues/889

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export-kubeconfig

# The source for our chmod buildpack lives here: https://github.com/eirini-forks/chmod-buildpack
echo "Adding korifi/chmod buildpack to ClusterStore"
kubectl patch clusterstore cf-default-buildpacks --type='json' -p='[{ "op": "add", "path": "/spec/sources/-", "value": { "image": "us-west1-docker.pkg.dev/cf-on-k8s-wg/buildpacks/chmod:latest" } }]'

echo "Adding korifi/chmod buildpack to Ruby group under ClusterBuilder"
updated_order="$(kubectl get clusterbuilder cf-kpack-cluster-builder -o json | jq '.spec.order[] | select(.group[].id=="paketo-buildpacks/ruby").group |= [{"id": "korifi/chmod"}] + .' | jq -n '.spec.order |= [inputs]')"
kubectl patch clusterbuilder cf-kpack-cluster-builder -p "$updated_order" --type=merge

