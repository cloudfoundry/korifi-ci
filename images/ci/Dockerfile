FROM golang:latest

ARG GCLOUD_VERSION="378.0.0"
ARG YQ_VERSION="v4.23.1"
ARG KBLD_VERSION="v0.32.0"
ARG KAPP_VERSION="v0.46.0"

ENV PATH="$GOPATH/bin:${PATH}"

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
RUN curl -sL https://get.helm.sh/helm-v3.5.3-linux-amd64.tar.gz | tar xz --strip-components=1 -C /usr/bin linux-amd64/helm && chmod +x /usr/bin/helm

# gcloud
RUN curl -sL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz | \
  tar -xz -C /usr/local
ENV PATH="/usr/local/google-cloud-sdk/bin:${PATH}"

# carvel
RUN curl -sL "https://github.com/vmware-tanzu/carvel-kapp/releases/download/${KAPP_VERSION}/kapp-linux-amd64" -o /usr/local/bin/kapp && \
  chmod +x /usr/local/bin/kapp

RUN curl -sL "https://github.com/vmware-tanzu/carvel-kbld/releases/download/${KBLD_VERSION}/kbld-linux-amd64" -o /usr/local/bin/kbld && \
  chmod +x /usr/local/bin/kbld
