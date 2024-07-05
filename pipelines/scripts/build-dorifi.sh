#!/bin/bash

set -euo pipefail

pushd korifi
{
  make build-dorifi
}
popd

cp korifi/tests/assets/dorifi/* dorifi
cp korifi/tests/assets/multi-process/* multi-process
cp korifi/tests/assets/sample-broker/* sample-broker
