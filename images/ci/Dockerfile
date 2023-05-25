FROM golang:latest

ENV PATH="$GOPATH/bin:${PATH}"
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True

# add APT custom repos
# gcloud
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B53DC80D13EDEF05

RUN echo "deb https://packages.cloud.google.com/apt cloud-sdk main" >/etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl -fsSLo /usr/share/keyrings/cloud.google.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# helm
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" >/etc/apt/sources.list.d/helm-stable-debian.list \
  && curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor >/usr/share/keyrings/helm.gpg

# githubcli
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list \
  && curl -fsSLo /usr/share/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg

# terraform
RUN release="$(awk -F= '/VERSION_CODENAME/ { print $2 }' /etc/os-release)" \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $release main" >/etc/apt/sources.list.d/hashicorp.list \
  && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor >/usr/share/keyrings/hashicorp-archive-keyring.gpg

RUN apt-get update \
  && apt-get install --yes \
       --no-install-recommends \
       apt-transport-https \
       ca-certificates \
       conntrack \
       gh \
       git \
       google-cloud-sdk \
       google-cloud-sdk-gke-gcloud-auth-plugin \
       gnupg2 \
       helm \
       iptables \
       jq \
       lsb-release \
       parallel \
       ruby-dev \
       shellcheck \
       software-properties-common \
       sshfs \
       sudo \
       terraform \
       unzip \
       vim \
       wget \
       zip \
  && rm -rf /var/lib/apt/lists/*

# kubectl
RUN curl -fsSLo /usr/bin/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x /usr/bin/kubectl

# CF CLI
RUN curl -fsSL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v8&source=github" \
  | tar -zx cf8 \
  && mv cf8 /usr/bin/cf \
  && chmod +x /usr/bin/cf

# ginkgo
RUN go install github.com/onsi/ginkgo/v2/ginkgo@latest

# shfmt
RUN go install mvdan.cc/sh/cmd/shfmt@latest

# yq
RUN curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
  && chmod a+x /usr/local/bin/yq

# carvel
RUN curl -fsSL https://carvel.dev/install.sh \
  | bash

# kubectl buildkit
RUN url="$(curl -sSfL https://api.github.com/repos/vmware-tanzu/buildkit-cli-for-kubectl/releases/latest | jq -r '.assets[]|select(.name|match("linux")).browser_download_url')" \
  && curl -sSfL "$url" \
  | tar -C /usr/local/bin -xzf -

# code climate
RUN curl -fsSLo /usr/local/bin/cc-test-reporter https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 \
  && chmod +x /usr/local/bin/cc-test-reporter

# yarn
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
  && sudo apt update \
  && sudo apt install -y yarn

# aws cli
RUN curl -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf awscliv2.zip aws

# bosh
RUN url="$(curl -sSfL https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest | jq -r '.assets[]|select(.name|match("linux-amd64")).browser_download_url')" \
  && curl -fsSLo /usr/bin/bosh "$url" \
  && chmod +x /usr/bin/bosh
