#!/bin/bash

set -euo pipefail

# for multi-registry image testing (tools/image)
export REGISTRY_DETAILS
REGISTRY_DETAILS="
- server: europe-docker.pkg.dev
  pathPrefix: europe-docker.pkg.dev/cf-on-k8s-wg/test
  username: _json_key_base64
  password: $(base64 -w0 <<<"$GCP_ARTIFACT_WRITER_KEY")

- server: 007801690126.dkr.ecr.eu-west-1.amazonaws.com
  repoName: 007801690126.dkr.ecr.eu-west-1.amazonaws.com/test
  username: AWS
  password: $(aws ecr get-login-password --region eu-west-1)
"

make -C "root/$DIR" "$TARGET"
