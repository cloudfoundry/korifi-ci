#!/bin/bash

set -euo pipefail

export GIT_COMMIT_SHA=$(<korifi/.git/ref)
export GIT_BRANCH=main

cc-test-reporter before-build

cc-test-reporter sum-coverage **/*.codeclimate.json -p $(ls **/*.codeclimate.json | wc -l) -o coverage.total.json
cc-test-reporter upload-coverage -i coverage.total.json
