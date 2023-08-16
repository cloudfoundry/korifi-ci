#!/bin/bash

set -euo pipefail

KUBECONFIG="$(realpath "$KUBECONFIG")"

source korifi-ci/pipelines/scripts/common/target.sh

SKIP_DEPLOY=true make -C korifi test-smoke
