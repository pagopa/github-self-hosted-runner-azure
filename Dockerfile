FROM ubuntu:22.04@sha256:a8fe6fd30333dc60fc5306982a7c51385c2091af1e0ee887166b40a905691fd0

RUN apt-get update && apt-get install -y curl

# Create a folder
RUN mkdir actions-runner
WORKDIR actions-runner

RUN GITHUB_RUNNER_VERSION="2.299.1" && \
    GITHUB_RUNNER_VERSION_SHA="147c14700c6cb997421b9a239c012197f11ea9854cd901ee88ead6fe73a72c74" && \
    curl -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
    echo "${GITHUB_RUNNER_VERSION_SHA}  actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c && \
    tar xzf ./actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz

RUN	bash bin/installdependencies.sh

# install zip, unip

RUN apt-get -y install zip unzip

# install az cli from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt#option-2-step-by-step-installation-instructions

RUN apt-get -y install ca-certificates curl wget apt-transport-https lsb-release gnupg

RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null && \
    AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

RUN apt-get update && apt-get -y install azure-cli

RUN az config set extension.use_dynamic_install=yes_without_prompt

# install python-pip

RUN apt-get -y install python-pip

# install kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management

RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    
RUN apt-get update && apt-get -y install kubectl

# install helm from https://helm.sh/docs/intro/install/#from-apt-debianubuntu

RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

RUN apt-get update && apt-get -y install helm

# install jq from https://stedolan.github.io/jq/download/

RUN apt-get update && apt-get -y install jq

# install yq from https://github.com/mikefarah/yq#install

RUN YQ_VERSION="v4.30.6" && \
    YQ_BINARY="yq_linux_amd64" && \
    wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | tar xz && mv ${YQ_BINARY} /usr/bin/yq

####

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
