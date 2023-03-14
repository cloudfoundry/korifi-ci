#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export KUBECONFIG=$HOME/.kube/config
export-kubeconfig

cd korifi
ginkgo ./tests/crds
