#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh

make -C korifi test-crds
