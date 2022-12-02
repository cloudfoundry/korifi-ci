FROM golang:latest

ARG BUILDKIT_CLI_VERSION="v0.1.6"
ARG GCLOUD_VERSION="410.0.0"
ARG HELM_VERSION="v3.10.2"
ARG TERRAFORM_VERSION="1.3.6"
ARG YQ_VERSION="v4.30.5"

ENV PATH="$GOPATH/bin:${PATH}"
ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True

RUN  apt-get update \
  && apt-get install --yes \
       --no-install-recommends \
       apt-transport-https \
       ca-certificates \
       curl \
       git \
       wget \
       jq \
       shellcheck \
       software-properties-common \
       lsb-release \
       unzip \
       vim \
       apt-transport-https \
       gnupg2 \
       sshfs \
       conntrack \
       iptables \
       sudo \
  && rm -rf /var/lib/apt/lists/*

# kubectl
RUN curl -Lo /usr/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  chmod +x /usr/bin/kubectl

# CF CLI
RUN curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v8&source=github" | tar -zx cf8 && \
  mv cf8 /usr/bin/cf && chmod +x /usr/bin/cf

# ginkgo && shfmt
RUN go install github.com/onsi/ginkgo/v2/ginkgo@latest
RUN go install mvdan.cc/sh/cmd/shfmt@latest

# yq
RUN curl -sLo yq https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
  && install yq /usr/bin/ \
  && rm -f yq

# gh cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list && \
  apt-get update && \
  apt-get install gh

# helm
RUN curl -sL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz | tar xz --strip-components=1 -C /usr/bin linux-amd64/helm && chmod +x /usr/bin/helm

# gcloud
RUN curl -sL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz | \
  tar -xz -C /usr/local
ENV PATH="/usr/local/google-cloud-sdk/bin:${PATH}"
RUN gcloud components install gke-gcloud-auth-plugin --quiet

# carvel
RUN curl -L https://carvel.dev/install.sh | bash

RUN curl -sL https://github.com/vmware-tanzu/buildkit-cli-for-kubectl/releases/download/${BUILDKIT_CLI_VERSION}/linux-${BUILDKIT_CLI_VERSION}.tgz | \
  tar -C /usr/local/bin -xzf -

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg >/usr/share/keyrings/githubcli-archive-keyring.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list && \
  apt update && \
  apt install gh

RUN curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 -o /usr/local/bin/cc-test-reporter && \
  chmod +x /usr/local/bin/cc-test-reporter

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list \
  && sudo apt update \
  && sudo apt install -y yarn

# aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf awscliv2.zip aws

# terraform
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      && mv terraform /usr/local/bin/ \
      && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
