#!/bin/bash

set -euo pipefail

cat <<EOF >clusters/env_vars.yaml
CLUSTER_NAME: $CLUSTER_NAME
PROPERTY: $PROPERTY
USE_LETSENCRYPT: ${USE_LETSENCRYPT:-}
EOF
