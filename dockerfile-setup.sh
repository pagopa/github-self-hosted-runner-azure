#!/usr/bin/env bash

echo "✅ Start apt get install base packages"

apt-get update \
    && apt-get -y install curl git vim \
    && apt-get -y install zip unzip \
    && apt-get -y install ca-certificates curl wget apt-transport-https lsb-release gnupg \
    && apt-get -y install jq \
    && apt-get -y icu-libs~=73 \
    && apt-get -y icu-data-full~=73 \
    && apt-get satisfy "python3-pip  (<= 22.1)" -y
    # install jq from https://stedolan.github.io/jq/download/

# 1) 554mb

# Test whoami
whoami

echo "✅ whoami > run as expected"

#
# Github Action runner
#
mkdir -p actions-runner
cd actions-runner || exit
# from https://github.com/actions/runner/releases
GITHUB_RUNNER_VERSION="${ENV_GITHUB_RUNNER_VERSION:-2.309.0}"
GITHUB_RUNNER_VERSION_SHA="${ENV_GITHUB_RUNNER_VERSION_SHA:-2974243bab2a282349ac833475d241d5273605d3628f0685bd07fb5530f9bb1a}"
curl -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
echo "${GITHUB_RUNNER_VERSION_SHA}  actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c
tar xzf ./actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
# 2) 1.09GB
# bash bin/installdependencies.sh
echo "✅ Installed > github action runner"
# 3) 1.13GB

#
# AZCLI
#
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg
chmod go+r /etc/apt/keyrings/microsoft.gpg
AZ_DIST=$(lsb_release -cs)
# we build only for amd64
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" | tee /etc/apt/sources.list.d/azure-cli.list
apt-get update \
  && apt-get -y install azure-cli
az config set extension.use_dynamic_install=yes_without_prompt
which az >/dev/null && echo "✅ Installed az" || echo "❌ failed to install az"

## Node and Yarn install
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/nodesource.gpg
NODE_MAJOR_VERSION="${ENV_NODE_MAJOR_VERSION:-20}"
echo "deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update \
    && apt-get -y install nodejs \
    && npm install -g yarn
which node >/dev/null && echo "✅ Installed node" || echo "❌ failed to install node"
which npm >/dev/null && echo "✅ Installed npm" || echo "❌ failed to install npm"
which yarn >/dev/null && echo "✅ Installed yarn" || echo "❌ failed to install yarn"

#
# KUBERNETES DEPENDENCIES
#
# install kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
# install helm from https://helm.sh/docs/intro/install/#from-apt-debianubuntu
curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor -o /etc/apt/keyrings/helm.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get satisfy "kubectl" -y
which kubectl >/dev/null && echo "✅ Installed kubectl" || echo "❌ failed to install kubectl"
apt-get satisfy "helm" -y
which helm >/dev/null && echo "✅ Installed helm" || echo "❌ failed to install helm"

#
# install yq from https://github.com/mikefarah/yq#install
#
YQ_VERSION="v4.40.7"
YQ_VERSION_SHA="b895bad59fe6a24d5c38a73d09f8b8e7cef45a5049e16504c02176ebed6d572e"
YQ_BINARY="yq_linux_amd64"
curl -fsSL https://github.com/mikefarah/yq/releases/download/"${YQ_VERSION}"/${YQ_BINARY}.tar.gz -o ${YQ_BINARY}.tar.gz
echo "${YQ_VERSION_SHA}" $YQ_BINARY.tar.gz | sha256sum -c
mkdir -p yq && tar xz -f ${YQ_BINARY}.tar.gz -C yq && mv yq/${YQ_BINARY} /usr/bin/yq
which yq >/dev/null && echo "✅ Installed yq" || echo "❌ failed to install yq"

#
# Kubelogin install (use kubectl to install packages)
#
KUBELOGIN_VERSION="0.0.34"
az aks install-cli --kubelogin-version "${KUBELOGIN_VERSION}"
which kubelogin >/dev/null && echo "✅ Installed kubelogin" || echo "❌ failed to install kubelogin"

#
# USER CONFIGURATIONS
#
useradd github
mkdir -p /home/github
chown -R github:github /home/github
chown -R github:github /actions-runner
