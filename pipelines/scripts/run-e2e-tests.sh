#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/gcloud-functions

export-kubeconfig

SKIP_DEPLOY=true make -C korifi test-e2e
