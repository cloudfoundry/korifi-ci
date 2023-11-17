#!/bin/bash

set -euo pipefail

run-with-timeout() {
  timeout --verbose --preserve-status --signal=SIGQUIT 30m $@
}
