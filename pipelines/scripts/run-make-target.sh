#!/bin/bash

set -euo pipefail

make -C "root/$DIR" "$TARGET"

pushd root
{
  idx=0
  for c in $(find "$DIR" -name cover.out); do
    cc-test-reporter format-coverage $c -t gocov -o ../coverage/$TARGET-$idx.codeclimate.json -p code.cloudfoundry.org/korifi
    idx=$((idx + 1))
  done
}
popd
