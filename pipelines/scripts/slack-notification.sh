#!/bin/bash

set -euo pipefail

curl -X POST "$SLACK_NOTIFICATION_URI" \
  -H "Content-Type: application/json" \
  -d '
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "Pipeline *$BUILD_PIPELINE_NAME* failed :cry:\n\nJob is *$BUILD_JOB_NAME*\nBuild name is *$BUILD_NAME*"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "View in Concourse"
          },
          "style": "danger",
          "url": "https://ci.korifi.cfapp.com/teams/$BUILD_TEAM_NAME/pipelines/$BUILD_PIPELINE_NAME/jobs/$BUILD_JOB_NAME/builds/$BUILD_NAME"
        }
      ]
    }
  ]
}
'
