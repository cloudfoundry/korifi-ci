#!/bin/bash

set -euo pipefail

pushd korifi
{
  make build-dorifi
}
popd

cp korifi/tests/e2e/assets/dorifi/* dorifi
