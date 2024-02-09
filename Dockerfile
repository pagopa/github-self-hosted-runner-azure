# from https://hub.docker.com/_/ubuntu/tags?page=1&name=22.04
FROM ubuntu:22.04@sha256:bcc511d82482900604524a8e8d64bf4c53b2461868dac55f4d04d660e61983cb

# see readme to understand wich version and use to use
ENV ENV_GITHUB_RUNNER_VERSION="2.313.0"
ENV ENV_GITHUB_RUNNER_VERSION_SHA=56910d6628b41f99d9a1c5fe9df54981ad5d8c9e42fc14899dcc177e222e71c4
# https://github.com/Azure/kubelogin/blob/master/CHANGELOG.md
ENV ENV_KUBELOGIN_VERSION=0.0.31
ENV ENV_YQ_VERSION="v4.30.6"
ENV NODE_MAJOR_VERSION="20"

WORKDIR /

COPY dockerfile-setup.sh dockerfile-setup.sh
RUN bash dockerfile-setup.sh

COPY github-runner-entrypoint.sh /github-runner-entrypoint.sh
RUN chmod +x /github-runner-entrypoint.sh

# changed user to avoid root user
USER github

RUN whoami && \
  az --version && \
  kubectl --help && \
  kubelogin --version && \
  helm --help && \
  yq --version && \
  node --version && \
  npm --version && \
  yarn --version

ENTRYPOINT ["/github-runner-entrypoint.sh"]
