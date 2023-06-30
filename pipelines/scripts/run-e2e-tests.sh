#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export KUBECONFIG=$HOME/.kube/config
export-kubeconfig

SKIP_DEPLOY=true DEFAULT_APP_BITS_PATH=$(readlink -f "$DEFAULT_APP_BITS_PATH") make -C korifi test-e2e
