# from https://hub.docker.com/_/ubuntu/tags?page=1&name=22.04
FROM ubuntu:22.04@sha256:bcc511d82482900604524a8e8d64bf4c53b2461868dac55f4d04d660e61983cb

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
