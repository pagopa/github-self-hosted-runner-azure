#!/usr/bin/env bash

INTERACTIVE="FALSE"

# Verify some Repo URL and token have been given, otherwise we must be interactive mode.
if [ -n "$GITHUB_REPOSITORY" ] && [ -n "$GITHUB_TOKEN" ]; then

  #
  # Legacy Container app configuration, with create and destroy agent
  #
  echo "🌊 start agent configuration"

  if [ "$(echo "$INTERACTIVE_MODE" | tr '[:upper:]' '[:lower:]')" == "true" ]; then
    INTERACTIVE="TRUE"
  fi

  # Calculate default configuration values.
  GITHUB_REPOSITORY_BANNER="$GITHUB_REPOSITORY"
  if [ -z "$GITHUB_REPOSITORY_BANNER" ]; then
    export GITHUB_REPOSITORY_BANNER="<empty repository url>"
  fi

  if [ -z "$RUNNER_NAME" ]; then
    RUNNER_NAME="$(hostname)"
    export RUNNER_NAME
  fi

  if [ -z "$WORK_DIR" ]; then
    export WORK_DIR=".workdir"
  fi

  # Calculate runner replacement policy.
  REPLACEMENT_POLICY="\n\n\n"
  REPLACEMENT_POLICY_LABEL="FALSE"
  if [ "$(echo "$REPLACE_EXISTING_RUNNER" | tr '[:upper:]' '[:lower:]')" == "true" ]; then
    REPLACEMENT_POLICY="Y\n\n"
    REPLACEMENT_POLICY_LABEL="TRUE"
  fi

  # Configure runner interactively, or with the given replacement policy.
  printf "ℹ️ Configuring GitHub Runner for %s\n\t" "$GITHUB_REPOSITORY_BANNER"
  printf "ℹ️ Runner Name: %s\n\t" "$RUNNER_NAME"
  printf "ℹ️ Working Directory: %s\n\t" "$WORK_DIR"
  printf "ℹ️ Replace Existing Runners: %s\n" "$REPLACEMENT_POLICY_LABEL"

  # actions-runner is a folder inside the github runner zip
  if [ "$INTERACTIVE" == "FALSE" ]; then
    echo -ne "$REPLACEMENT_POLICY" | ./config.sh --url "$GITHUB_REPOSITORY" --token "$GITHUB_TOKEN" --name "$RUNNER_NAME" --work "$WORK_DIR" --labels "$LABELS" --disableupdate
  else
    #<https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners>
    ./config.sh \
      --url "$GITHUB_REPOSITORY" \
      --token "$GITHUB_TOKEN" \
      --name "$RUNNER_NAME" \
      --work "$WORK_DIR" \
      --labels "$LABELS" \
      --disableupdate
    echo "✅ config.sh launched"
  fi

  # Start the runner.
  ./run.sh
  echo "🚀 Executing GitHub Runner for $GITHUB_REPOSITORY"

elif [ -n "$GITHUB_PAT" ]; then

  # Retrieve a short lived runner registration token using the PAT
  REGISTRATION_TOKEN="$(curl -X POST -fsSL \
    -H 'Accept: application/vnd.github.v3+json' \
    -H "Authorization: Bearer $GITHUB_PAT" \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "$REGISTRATION_TOKEN_API_URL" \
    | jq -r '.token')"

  #<https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners>
  ./config.sh \
    --url "${REPO_URL}" \
    --token "${REGISTRATION_TOKEN}" \
    --unattended \
    --disableupdate \
    --ephemeral \
    --replace \
    --labels "$LABELS" \
    && ./run.sh

  export GITHUB_PAT=_REDACTED_
  export REGISTRATION_TOKEN=_REDACTED_

else

  app_id="$GITHUB_APP_ID"
  pem_path="./key.pem"
  printf '%b\n' "$GITHUB_APP_KEY" > $pem_path

  now=$(date +%s)
  iat=$((${now} - 60)) # Issues 60 seconds in the past
  exp=$((${now} + 600)) # Expires 10 minutes in the future

  b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

  header_json='{
      "typ":"JWT",
      "alg":"RS256"
  }'
  # Header encode
  header=$( echo -n "${header_json}" | b64enc )

  payload_json="{
      \"iat\":${iat},
      \"exp\":${exp},
      \"iss\":\"${app_id}\"
  }"
  # Payload encode
  payload=$( echo -n "${payload_json}" | b64enc )

  # Signature
  header_payload="${header}"."${payload}"
  signature=$(
      openssl dgst -sha256 -sign "${pem_path}" \
      <(echo -n "${header_payload}") | b64enc
  )

  # Create JWT
  JWT="${header_payload}"."${signature}"

  ACCESS_TOKEN="$(curl --request POST \
    --header 'Accept: application/vnd.github+json' \
    --header "Authorization: Bearer $JWT" \
    --header 'X-GitHub-Api-Version: 2022-11-28' \
    "https://api.github.com/app/installations/$GITHUB_APP_INSTALLATION_ID/access_tokens" \
    | jq -r '.token')"

  # Retrieve a short lived runner registration token using the ACCESS_TOKEN
  REGISTRATION_TOKEN="$(curl -X POST -fsSL \
    -H 'Accept: application/vnd.github.v3+json' \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    "$REGISTRATION_TOKEN_API_URL" \
    | jq -r '.token')"

  #<https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners>
  ./config.sh \
    --url "${REPO_URL}" \
    --token "${REGISTRATION_TOKEN}" \
    --unattended \
    --disableupdate \
    --ephemeral \
    --replace \
    --labels "$LABELS" \
    && ./run.sh

  rm "$pem_path"
  export signature=_REDACTED_
  export JWT=_REDACTED_
  export GITHUB_APP_KEY=_REDACTED_
  export ACCESS_TOKEN=_REDACTED_
  export REGISTRATION_TOKEN=_REDACTED_

fi
