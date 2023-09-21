#!/usr/bin/env bash

# Retrieve a short lived runner registration token using the PAT
REGISTRATION_TOKEN="$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $GITHUB_PAT" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$REGISTRATION_TOKEN_API_URL" \
  | jq -r '.token')"

./actions-runner/config.sh \
  --url $REPO_URL \
  --token $REGISTRATION_TOKEN \
  --unattended \
  --ephemeral \
  --disableupdate

./actions-runner/run.sh
