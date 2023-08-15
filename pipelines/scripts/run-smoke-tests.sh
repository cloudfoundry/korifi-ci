#!/bin/bash

set -euo pipefail

KUBECONFIG="$(realpath "$KUBECONFIG")"

source korifi-ci/pipelines/scripts/common/target.sh

make -C korifi test-smoke
