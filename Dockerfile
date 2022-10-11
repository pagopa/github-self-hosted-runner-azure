FROM ubuntu:22.04@sha256:a8fe6fd30333dc60fc5306982a7c51385c2091af1e0ee887166b40a905691fd0

# SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update
RUN apt-get install curl sudo bash -y

# Create a folder
RUN mkdir actions-runner && cd actions-runner
RUN curl -o actions-runner-linux-x64-2.298.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.298.2/actions-runner-linux-x64-2.298.2.tar.gz
RUN echo "0bfd792196ce0ec6f1c65d2a9ad00215b2926ef2c416b8d97615265194477117  actions-runner-linux-x64-2.298.2.tar.gz" | sha256sum -c
RUN tar xzf ./actions-runner-linux-x64-2.298.2.tar.gz
RUN rm actions-runner-linux-x64-2.298.2.tar.gz

RUN	bash bin/installdependencies.sh

COPY entrypoint.sh /actions-runner/entrypoint.sh

RUN useradd github && \
    echo "github ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -aG sudo github && \
    chown -R github:github /actions-runner && \
    chmod +x /actions-runner/entrypoint.sh

USER github
ENTRYPOINT ["/actions-runner/entrypoint.sh"]
