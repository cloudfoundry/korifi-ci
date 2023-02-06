#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

pushd "$SCRIPT_DIR"
{
  for config in **/pipeline.yml; do
    pipeline="$(dirname $config)"
    echo "Applying pipeline "$pipeline"..."
    fly --target korifi set-pipeline --pipeline "$pipeline" --config $config
    fly --target=korifi expose-pipeline --pipeline="$pipeline"
  done
}
popd
