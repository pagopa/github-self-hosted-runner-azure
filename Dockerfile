FROM ghcr.io/actions/actions-runner:2.328.0@sha256:db0dcae6d28559e54277755a33aba7d0665f255b3bd2a66cdc5e132712f155e0 AS base

USER root

RUN apt-get update \
    && apt-get -y install curl git \
    && apt-get -y install jq \
    && apt-get -y install zip unzip \
    && apt-get -y install build-essential \
    && apt-get -y install openjdk-17-jdk \
    && apt-get -y install ca-certificates wget apt-transport-https lsb-release gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/

FROM base AS deps
RUN bash bin/installdependencies.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM deps AS deps-az
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
RUN AZ_REPO=$(lsb_release -cs) && \
    echo "deb [arch=$(dpkg --print-architecture)] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-get update && \
    apt-get -y install azure-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN az config set extension.use_dynamic_install=yes_without_prompt
ENV KUBELOGIN_VERSION="${ENV_KUBELOGIN_VERSION:-0.0.26}"
RUN az aks install-cli --kubelogin-version "${KUBELOGIN_VERSION}"

FROM deps-az AS deps-kube
RUN curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN apt-get update \
    && apt-get satisfy "helm" -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM deps-kube AS deps-yq
ENV YQ_VERSION="v4.30.6"
ENV YQ_BINARY="yq_linux_amd64"
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | tar xz && mv ${YQ_BINARY} /usr/bin/yq

FROM  deps-yq AS deps-node-yarn
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/nodesource.gpg
ENV NODE_MAJOR_VERSION="20"
RUN echo "deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR_VERSION.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update \
    && apt-get -y install nodejs \
    && sleep  5s \
    && npm install --global yarn@v1.22.22 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM  deps-node-yarn AS deps-docker-compose
RUN curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
    && chmod +x /usr/local/bin/docker-compose 

FROM deps-docker-compose AS final
COPY ./github-runner-entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

USER runner

RUN whoami \
  && echo "az cli: $(az version)" \
  && echo "kubectl client: $(kubectl version --client -o yaml)" \
  && echo "kubelogin client: $(kubelogin --version)" \
  && echo "helm: $(helm version)" \
  && echo "yq: $(yq --version)" \
  && echo "java: $(java --version)" \
  && echo "node: $(node --version)" \
  && echo "npm: $(npm --version)" \
  && echo "yarn: $(yarn --version)" \
  && echo "docker-compose: $(docker-compose --version)"

ENTRYPOINT ["./entrypoint.sh"]
