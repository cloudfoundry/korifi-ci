#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export KUBECONFIG=$HOME/.kube/config
export-kubeconfig

SKIP_DEPLOY=true make -C korifi test-e2e
