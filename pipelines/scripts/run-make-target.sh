#!/bin/bash

set -euo pipefail

make -C "root/$DIR" "$TARGET"

idx=0
for c in $(find "root/$DIR" -name cover.out); do
  cc-test-reporter format-coverage $c -t gocov -o coverage/$TARGET-$idx.codeclimate.json -p $(dirname $c)
  idx=$((idx + 1))
done
