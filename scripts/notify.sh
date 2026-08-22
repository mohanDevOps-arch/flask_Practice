#!/usr/bin/env bash
# Publish a success/failure notification to the CI/CD SNS topic.
# Called from the GitHub Actions workflow; expects a set of env vars.
#
# Required env:
#   TOPIC_ARN, JOB_STATUS (success|failure|cancelled)
# Optional env:
#   FAILED_STAGE, IMAGE_TAG, IMAGE_URI, EC2_HOST, APP_PORT
#   GITHUB_REPOSITORY, GITHUB_REF_NAME, GITHUB_SHA, GITHUB_RUN_ID,
#   GITHUB_SERVER_URL, GITHUB_ACTOR, GITHUB_WORKFLOW  (auto-set by Actions)

set -euo pipefail

: "${TOPIC_ARN:?TOPIC_ARN required}"
: "${JOB_STATUS:?JOB_STATUS required}"

APP_PORT="${APP_PORT:-5000}"
SHORT_SHA="${GITHUB_SHA:0:12}"
RUN_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

if [[ "$JOB_STATUS" == "success" ]]; then
  SUBJECT="[CI/CD SUCCESS] ${GITHUB_REPOSITORY} @ ${GITHUB_REF_NAME} (${SHORT_SHA})"
  BODY=$(cat <<EOF
The pipeline succeeded and the new image is running on EC2.

Repository   : ${GITHUB_REPOSITORY}
Branch       : ${GITHUB_REF_NAME}
Commit       : ${GITHUB_SHA}
Image tag    : ${IMAGE_TAG:-<unknown>}
Image URI    : ${IMAGE_URI:-<unknown>}
EC2 target   : ${EC2_HOST:-<unknown>}:${APP_PORT}
Health URL   : http://${EC2_HOST:-<unknown>}:${APP_PORT}/health
Pipeline run : ${RUN_URL}

Triggered by : ${GITHUB_ACTOR}
Workflow     : ${GITHUB_WORKFLOW}
EOF
  )
else
  SUBJECT="[CI/CD FAILURE] ${GITHUB_REPOSITORY} @ ${GITHUB_REF_NAME} — stage: ${FAILED_STAGE:-unknown}"
  BODY=$(cat <<EOF
The pipeline FAILED. Details below.

Failed stage : ${FAILED_STAGE:-unknown}
Repository   : ${GITHUB_REPOSITORY}
Branch       : ${GITHUB_REF_NAME}
Commit       : ${GITHUB_SHA}
Attempted tag: ${IMAGE_TAG:-<not built>}
Pipeline run : ${RUN_URL}

Triggered by : ${GITHUB_ACTOR}
Workflow     : ${GITHUB_WORKFLOW}

Investigate the failed stage in the run logs.
EOF
  )
fi

aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --subject   "$SUBJECT" \
  --message   "$BODY" \
  --output    text > /dev/null

echo "Notified SNS: $SUBJECT"
