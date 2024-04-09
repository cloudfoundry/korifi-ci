#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh
source korifi-ci/pipelines/scripts/common/run-with-timeout.sh

export SKIP_DEPLOY=true
export DEFAULT_APP_BITS_PATH=$(readlink -f "$DEFAULT_APP_BITS_PATH")
run-with-timeout make -C korifi test-crds
