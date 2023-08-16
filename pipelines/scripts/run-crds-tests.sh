#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh

SKIP_DEPLOY=true make -C korifi test-crds
