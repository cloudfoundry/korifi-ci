#!/bin/bash

set -euo pipefail

source korifi-ci/pipelines/scripts/common/target.sh

appName=dorifiii
cf target -o "$appName" -s "$appName"

appURL="$(cf app "$appName" | grep routes | awk '{print $2}')"
appResponse="$(curl "https://$appURL")"

if [[ "$appResponse" != "Hi, I'm Dorifi!" ]]; then
  echo "Unexpected response from app: $appResponse"
  exit 1
fi

podInfo="$(
  kubectl get pods \
    --namespace="$(cf space $appName --guid)" \
    --selector="korifi.cloudfoundry.org/app-guid=$(cf app $appName --guid)" \
    --output=custom-columns='NAME:metadata.name,STATE:status.phase,STARTED:status.startTime' \
    --no-headers
)"

podName="$(awk '{print $1}' <<<$podInfo)"
podState="$(awk '{print $2}' <<<$podInfo)"
podStartTime="$(awk '{print $3}' <<<$podInfo)"

podStartTimeSeconds="$(date -d $podStartTime +"%s")"
now=$(date +"%s")
podAgeMin=$(((now - podStartTimeSeconds) / 60))

echo "App pod stats:"
echo "Pod name: "$podName
echo "Pod state: "$podState
echo "Pod age (min): "$podAgeMin

if [[ "$podState" != "Running" ]]; then
  echo "Unexpected state $podState of pod: $podName"
  exit 1
fi

if (("$podAgeMin" < 30)); then
  echo "Age of pod $podName too small: ${podAgeMin}m. Pod might have been restarted during upgrade."
  exit 1
fi
