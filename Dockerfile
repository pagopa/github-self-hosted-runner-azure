# from https://hub.docker.com/_/ubuntu/tags?page=1&name=22.04
FROM ubuntu:22.04@sha256:965fbcae990b0467ed5657caceaec165018ef44a4d2d46c7cdea80a9dff0d1ea

# see readme to understand wich version and use to use
ENV ENV_GITHUB_RUNNER_VERSION="2.309.0"
ENV ENV_GITHUB_RUNNER_VERSION_SHA=2974243bab2a282349ac833475d241d5273605d3628f0685bd07fb5530f9bb1a
# https://github.com/Azure/kubelogin/blob/master/CHANGELOG.md
ENV ENV_KUBELOGIN_VERSION=0.0.31
ENV ENV_YQ_VERSION="v4.30.6"
ENV NODE_MAJOR_VERSION="20"
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
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
