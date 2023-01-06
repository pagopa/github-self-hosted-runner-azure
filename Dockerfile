# from https://hub.docker.com/_/ubuntu/tags?page=1&name=22.04
FROM ubuntu:22.04@sha256:965fbcae990b0467ed5657caceaec165018ef44a4d2d46c7cdea80a9dff0d1ea

COPY install_script.sh install_script.sh

RUN bash install_script.sh

RUN useradd github && \
    mkdir -p /home/github && \
    chown -R github:github /home/github && \
    chown -R github:github /actions-runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER github

WORKDIR /

RUN whoami && \
    az --version && \
    kubectl --help && \
    helm --help && \
    yq --version

ENTRYPOINT ["/entrypoint.sh"]
