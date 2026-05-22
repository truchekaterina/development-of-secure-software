#!/bin/sh
# Lab 7 — scan only new commits in pipeline (not entire Juice Shop history)
set -e
gitleaks version

if [ -n "$CI_MERGE_REQUEST_IID" ]; then
  MR_BASE="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-}"
  if [ -z "$MR_BASE" ]; then
    LOG_OPTS="-1"
    echo "Gitleaks MR scan: last commit only (no diff base)"
  else
    LOG_OPTS="${MR_BASE}..${CI_COMMIT_SHA}"
    echo "Gitleaks MR scan: $LOG_OPTS"
  fi
elif [ "$CI_COMMIT_BEFORE_SHA" = "0000000000000000000000000000000000000000" ] || [ -z "$CI_COMMIT_BEFORE_SHA" ]; then
  LOG_OPTS="-1"
  echo "Gitleaks scan: last commit only (-1)"
else
  LOG_OPTS="${CI_COMMIT_BEFORE_SHA}..${CI_COMMIT_SHA}"
  echo "Gitleaks push scan: $LOG_OPTS"
fi

gitleaks detect \
  --source . \
  --config .gitleaks.toml \
  --redact \
  --log-opts="$LOG_OPTS" \
  --report-format json \
  --report-path gitleaks-report.json \
  --exit-code 1

test -s gitleaks-report.json
