FROM mcr.microsoft.com/dotnet/core/sdk:3.1

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
    && apt-get install -y azure-cli \
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

WORKDIR /app

RUN git clone https://github.com/mjungnickel18/papyruscs \
    && cd /tmp && mkdir pack && wget https://aka.ms/resourcepacktemplate && unzip resourcepacktemplate -d pack \
    && cd /app/papyruscs && rm -rf textures/* && mv /tmp/pack/textures/terrain_texture.json ./textures/ && mv /tmp/pack/textures/blocks ./textures/ \
    && dotnet publish PapyrusCs -c Debug --self-contained --runtime linux-x64 \
    && chmod +x PapyrusCs/bin/Debug/netcoreapp3.1/linux-x64/PapyrusCs \
    && ln -s $PWD/PapyrusCs/bin/Debug/netcoreapp3.1/linux-x64/PapyrusCs /usr/bin/PapyrusCs

WORKDIR /

RUN mkdir -p /opt/minecraft
COPY *.sh /opt/minecraft/


