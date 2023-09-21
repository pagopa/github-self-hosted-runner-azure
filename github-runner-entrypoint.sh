printf "Before token: $REPO_URL; $GITHUB_PAT; $REGISTRATION_TOKEN_API_URL;\n"

# Retrieve a short lived runner registration token using the PAT
REGISTRATION_TOKEN="$(curl -X POST -fsSL \
  -H 'Accept: application/vnd.github.v3+json' \
  -H "Authorization: Bearer $GITHUB_PAT" \
  -H 'X-GitHub-Api-Version: 2022-11-28' \
  "$REGISTRATION_TOKEN_API_URL" \
  | jq -r '.token')"

printf "After token: $REGISTRATION_TOKEN;\n"

./actions-runner/config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --unattended --ephemeral --disableupdate

printf "config run successfully\n"

./actions-runner/run.sh
