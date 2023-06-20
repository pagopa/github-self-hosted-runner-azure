# from https://hub.docker.com/_/ubuntu/tags?page=1&name=22.04
FROM ubuntu:22.04@sha256:965fbcae990b0467ed5657caceaec165018ef44a4d2d46c7cdea80a9dff0d1ea

ENV ENV_GITHUB_RUNNER_VERSION="2.305.0"
ENV ENV_GITHUB_RUNNER_VERSION_SHA=737bdcef6287a11672d6a5a752d70a7c96b4934de512b7eb283be6f51a563f2f
ENV ENV_YQ_VERSION="v4.30.6"
ENV ENV_KUBELOGIN_VERSION=0.0.27

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
  yq --version

ENTRYPOINT ["/github-runner-entrypoint.sh"]
