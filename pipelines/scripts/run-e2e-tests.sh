#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions
source korifi-ci/pipelines/scripts/common/run-with-timeout.sh

export KUBECONFIG=$HOME/.kube/config
export-kubeconfig

export SKIP_DEPLOY=true
export DEFAULT_APP_BITS_PATH=$(readlink -f "$DEFAULT_APP_BITS_PATH")
run-with-timeout make -C korifi test-e2e
