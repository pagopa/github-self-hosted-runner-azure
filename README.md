# github-self-hosted-runner-azure

## How to use

Every time you want to update the runner you have to do the following:

* go to the following page: <https://github.com/actions/runner/releases> and choose the latest runner
* on the page of the chosen release, you need to take two pieces of info:

  * the version of the runner

  * the sha of the `actions-runner-linux-x64` version these two info must be inserted in the Dockerfile respectively in the variable: `ENV_GITHUB_RUNNER_VERSION` and `ENV_GITHUB_RUNNER_VERSION_SHA`

* run a local build

* Push your code and be sure that the action `beta-docker-branch` runs correctly
