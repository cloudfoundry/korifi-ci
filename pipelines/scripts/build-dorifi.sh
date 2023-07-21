#!/bin/bash

set -euo pipefail

pushd korifi
{
  make build-dorifi
}
popd

cp korifi/tests/assets/dorifi/* dorifi
