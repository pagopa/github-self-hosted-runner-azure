# from https://hub.docker.com/_/ubuntu/tags?page=1&name=22.04
FROM ubuntu:22.04@sha256:965fbcae990b0467ed5657caceaec165018ef44a4d2d46c7cdea80a9dff0d1ea as base

# Install base package
RUN apt-get update \
    && apt-get install -y curl git vim \
    && apt-get -y install zip unzip \
    && apt-get -y install ca-certificates curl wget apt-transport-https lsb-release gnupg

FROM base as azcli

RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
    && AZ_REPO=$(lsb_release -cs) \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update && apt-get -y install azure-cli \
    && az config set extension.use_dynamic_install=yes_without_prompt

FROM azcli as pip

#
# install python-pip
#
RUN apt-get update \
    && apt-get satisfy "python3-pip  (<= 22.1)" -y

#
#
#
FROM azcli as k8s
# configure kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
# Configure helm from https://helm.sh/docs/intro/install/#from-apt-debianubuntu
RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - \
    && echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

# install yq from https://github.com/mikefarah/yq#install
RUN YQ_VERSION="v4.30.6" \
    && YQ_BINARY="yq_linux_amd64" \
    && wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | tar xz && mv ${YQ_BINARY} /usr/bin/yq

# install kubectl, helm and jq
RUN apt-get update && apt-get satisfy "kubectl (<=1.26.1)" -y \
    && apt-get update && apt-get satisfy "helm (<=3.12.1)" -y \
    && apt-get -y install jq

#
# Github
#
FROM k8s as github

# from https://github.com/actions/runner/releases
RUN mkdir -p actions-runner \
    && cd actions-runner \
    && GITHUB_RUNNER_VERSION="2.301.1" \
    && GITHUB_RUNNER_VERSION_SHA="3ee9c3b83de642f919912e0594ee2601835518827da785d034c1163f8efdf907" \
    && curl --limit-rate 10G -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && echo "${GITHUB_RUNNER_VERSION_SHA}  actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c \
    && tar xzf ./actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz \
    && bash bin/installdependencies.sh

RUN useradd github \
    && mkdir -p /home/github \
    && chown -R github:github /home/github \
    && chown -R github:github /actions-runner

# COPY install_script.sh install_script.sh

# RUN bash install_script.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER github

WORKDIR /

RUN whoami && \
    az --version && \
    kubectl --help && \
    helm --help && \
    yq --version



# ENTRYPOINT ["/bin/bash","-c", "/entrypoint.sh"]
# CMD ["entrypoint.sh"]
