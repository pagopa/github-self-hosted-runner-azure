FROM ubuntu:22.04@sha256:a8fe6fd30333dc60fc5306982a7c51385c2091af1e0ee887166b40a905691fd0

RUN apt-get update
RUN apt-get install curl -y

# Create a folder
RUN mkdir actions-runner
WORKDIR actions-runner

RUN curl -o actions-runner-linux-x64-2.298.2.tar.gz -L https://github.com/actions/runner/releases/download/v2.298.2/actions-runner-linux-x64-2.298.2.tar.gz && \
    echo "0bfd792196ce0ec6f1c65d2a9ad00215b2926ef2c416b8d97615265194477117  actions-runner-linux-x64-2.298.2.tar.gz" | sha256sum -c && \
    tar xzf ./actions-runner-linux-x64-2.298.2.tar.gz && \
    rm actions-runner-linux-x64-2.298.2.tar.gz

RUN	bash bin/installdependencies.sh

RUN useradd github && \
    chown -R github:github /actions-runner
#     usermod -aG sudo github && \
#     echo "github ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER github

WORKDIR /

ENTRYPOINT ["/entrypoint.sh"]
