#!/bin/bash

set -euo pipefail

KUBECONFIG="$(realpath "$KUBECONFIG")"

source korifi-ci/pipelines/scripts/common/target.sh
source korifi-ci/pipelines/scripts/common/run-with-timeout.sh

export SKIP_DEPLOY=true
run-with-timeout make -C korifi test-smoke
