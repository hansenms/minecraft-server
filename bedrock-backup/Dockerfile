FROM ubuntu

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
ARG HELM_VERSION="v3.2.1"
ARG KUBE_VERSION="v1.18.1"
ARG AZURE_CLI_VERSION="2.7.0-1~focal"

RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog curl wget unzip 2>&1 \
    && apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common lsb-release \
    && apt-get install -y libgdiplus libc6-dev \
    # Install kubectl
    && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    #
    # Install Helm
    && curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash -s -- -v $HELM_VERSION \
    #
    # Install the Azure CLI
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list \
    && curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - 2>/dev/null \
    && apt-get update \
    && apt-get install -y azure-cli=$AZURE_CLI_VERSION \
    #
    # Install jq
    && apt-get install -y jq \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog

RUN mkdir -p /opt/minecraft
COPY *.sh /opt/minecraft/

RUN mkdir -p /opt/papyruscs \
    && cd /opt/papyruscs \
    && wget -q https://github.com/mjungnickel18/papyruscs/releases/download/v0.5.0/papyruscs-dotnetcore-0.5.0-linux64.zip \
    && unzip *.zip \
    && chmod +x PapyrusCs

