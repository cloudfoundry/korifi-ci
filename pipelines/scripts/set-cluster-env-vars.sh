#!/bin/bash

set -euo pipefail

cat <<EOF >clusters/env_vars.yaml
CLUSTER_NAME: $CLUSTER_NAME
NODE_MACHINE_TYPE: $NODE_MACHINE_TYPE
EOF
