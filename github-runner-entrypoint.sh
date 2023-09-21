#!/usr/bin/env bash

# INTERACTIVE="FALSE"
# if [ "$(echo "$INTERACTIVE_MODE" | tr '[:upper:]' '[:lower:]')" == "true" ]; then
# 	INTERACTIVE="TRUE"
# fi

# # Verify some Repo URL and token have been given, otherwise we must be interactive mode.
# if [ -z "$GITHUB_REPOSITORY" ] || [ -z "$GITHUB_TOKEN" ]; then
# 	if [ "$INTERACTIVE" == "FALSE" ]; then
# 		echo "GITHUB_REPOSITORY and GITHUB_TOKEN cannot be empty"
# 		exit 1
# 	fi
# fi

# # Calculate default configuration values.
# GITHUB_REPOSITORY_BANNER="$GITHUB_REPOSITORY"
# if [ -z "$GITHUB_REPOSITORY_BANNER" ]; then
# 	export GITHUB_REPOSITORY_BANNER="<empty repository url>"
# fi

# if [ -z "$RUNNER_NAME" ]; then
# 	RUNNER_NAME="$(hostname)"
#   export RUNNER_NAME
# fi

# if [ -z "$WORK_DIR" ]; then
# 	export WORK_DIR=".workdir"
# fi

# # Calculate runner replacement policy.
# REPLACEMENT_POLICY="\n\n\n"
# REPLACEMENT_POLICY_LABEL="FALSE"
# if [ "$(echo "$REPLACE_EXISTING_RUNNER" | tr '[:upper:]' '[:lower:]')" == "true" ]; then
# 	REPLACEMENT_POLICY="Y\n\n"
# 	REPLACEMENT_POLICY_LABEL="TRUE"
# fi

# # Configure runner interactively, or with the given replacement policy.
# printf "Configuring GitHub Runner for %s\n\t" "$GITHUB_REPOSITORY_BANNER"
# printf "Runner Name: %s\n\t" "$RUNNER_NAME"
# printf "Working Directory: %s\n\t" "$WORK_DIR"
# printf "Replace Existing Runners: %s\n" "$REPLACEMENT_POLICY_LABEL"

# # actions-runner is a folder inside the github runner zip
# if [ "$INTERACTIVE" == "FALSE" ]; then
# 	echo -ne "$REPLACEMENT_POLICY" | ./actions-runner/config.sh --url "$GITHUB_REPOSITORY" --token "$GITHUB_TOKEN" --name "$RUNNER_NAME" --work "$WORK_DIR" --labels "$LABELS" --disableupdate
# else
# 	./actions-runner/config.sh --url "$GITHUB_REPOSITORY" --token "$GITHUB_TOKEN" --name "$RUNNER_NAME" --work "$WORK_DIR" --labels "$LABELS" --disableupdate
# fi

# # Start the runner.
# printf "Executing GitHub Runner for %s\n" "$GITHUB_REPOSITORY"
# ./actions-runner/run.sh

printf "Before token: $REPO_URL; $GITHUB_PAT; $REGISTRATION_TOKEN_API_URL;\n"

# Retrieve a short lived runner registration token using the PAT
REGISTRATION_TOKEN="$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $GITHUB_PAT" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$REGISTRATION_TOKEN_API_URL" \
  | jq -r '.token')"

printf "After token: $REGISTRATION_TOKEN;\n"

./actions-runner/config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --unattended --ephemeral

printf "config run successfully\n"

./actions-runner/run.sh
