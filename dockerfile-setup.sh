#!/usr/bin/env bash

echo "✅ Start apt get install base packages"

apt-get update \
    && apt-get -y install curl git vim \
    && apt-get -y install zip unzip \
    && apt-get -y install ca-certificates curl wget apt-transport-https lsb-release gnupg \
    && apt-get -y install jq \
    && apt-get satisfy "python3-pip  (<= 22.1)" -y
    # install jq from https://stedolan.github.io/jq/download/

# Test whoami
whoami

echo "✅ whoami > run as expected"

#
# Github Action runner
#
mkdir -p actions-runner
cd actions-runner || exit

# from https://github.com/actions/runner/releases
GITHUB_RUNNER_VERSION="${ENV_GITHUB_RUNNER_VERSION:-2.310.2}"
GITHUB_RUNNER_VERSION_SHA="${ENV_GITHUB_RUNNER_VERSION_SHA:-fb28a1c3715e0a6c5051af0e6eeff9c255009e2eec6fb08bc2708277fbb49f93}"
curl -o actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
echo "${GITHUB_RUNNER_VERSION_SHA}  actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz" | sha256sum -c
tar xzf ./actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz

bash bin/installdependencies.sh
echo "✅ Installed > github action runner"

#
# AZCLI
#
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list

apt-get update \
  && apt-get -y install azure-cli

az config set extension.use_dynamic_install=yes_without_prompt

## Test azcli
az --version
echo "✅ Installed > azcli"

## Node and Yarn install 
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/nodesource.gpg
NODE_MAJOR_VERSION="${ENV_NODE_MAJOR_VERSION:-20}"
echo "deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
apt-get update \
    && apt-get -y install nodejs \
    && npm install -g yarn

## Node and Yarn test
node -v
npm -v
yarn -v
echo "✅ Installed Node & Yarn"

#
# KUBERNETES DEPENDENCIES
#
# install kubectl from https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

# install helm from https://helm.sh/docs/intro/install/#from-apt-debianubuntu
curl https://baltocdn.com/helm/signing.asc | apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

apt-get update
echo "✅ Configure kubernetes & Helm for installation"


apt-get satisfy "kubectl" -y
## Test kubectl
kubectl --help
echo "✅ Installed kubernetes"

apt-get satisfy "helm" -y
## Test helm
helm --help
echo "✅ Installed kubernetes"

# install yq from https://github.com/mikefarah/yq#install
YQ_VERSION="${ENV_YQ_VERSION:-v4.30.6}"
YQ_BINARY="yq_linux_amd64"
wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | tar xz && mv ${YQ_BINARY} /usr/bin/yq
echo "✅ Installed YQ"

## Test YQ
yq --version

# Kubelogin install (use kubectl to install packages)
KUBELOGIN_VERSION="${ENV_KUBELOGIN_VERSION:-0.0.26}"
az aks install-cli --kubelogin-version "${KUBELOGIN_VERSION}"
## Test kubelogin
kubelogin --version
echo "✅ Installed kubelogin"

#
# USER CONFIGURATIONS
#
useradd github
mkdir -p /home/github
chown -R github:github /home/github
chown -R github:github /actions-runner
