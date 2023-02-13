#!/usr/bin/env bash

echo "[INFO] Start apt get install base packages"

apt-get update \
    && apt-get -y install curl git vim \
    && apt-get -y install zip unzip \
    && apt-get -y install ca-certificates curl wget apt-transport-https lsb-release gnupg \
    && apt-get -y install jq \
    && apt-get satisfy "python3-pip  (<= 22.1)" -y
    # install jq from https://stedolan.github.io/jq/download/

#
# Github Action runner
#
echo "[INFO] Install github action runner"
mkdir -p actions-runner
cd actions-runner || exit

# from https://github.com/actions/runner/releases
GITHUB_RUNNER_VERSION="2.300.2"
GITHUB_RUNNER_VERSION_SHA="ed5bf2799c1ef7b2dd607df66e6b676dff8c44fb359c6fedc9ebf7db53339f0c"
curl -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
echo "${GITHUB_RUNNER_VERSION_SHA}  actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c
tar xzf ./actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz

bash bin/installdependencies.sh

#
# AZCLI
#
echo "[INFO] Install azcli"

curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

apt-get update && apt-get -y install azure-cli

az config set extension.use_dynamic_install=yes_without_prompt

#
# KUBERNETES DEPENDENCIES
#
# install kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
echo "[INFO] Install kubernetes"

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# install helm from https://helm.sh/docs/intro/install/#from-apt-debianubuntu
curl https://baltocdn.com/helm/signing.asc | apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

apt-get update \
    && apt-get satisfy "kubectl (<=1.26.1)" -y \
    && apt-get update && apt-get satisfy "helm (<=3.12.1)" -y

# install yq from https://github.com/mikefarah/yq#install
YQ_VERSION="v4.30.6"
YQ_BINARY="yq_linux_amd64"
wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | tar xz && mv ${YQ_BINARY} /usr/bin/yq

#
# USER CONFIGURATIONS
#
useradd github
mkdir -p /home/github
chown -R github:github /home/github
chown -R github:github /actions-runner
