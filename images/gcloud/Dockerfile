FROM google/cloud-sdk

ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True

# add APT custom repos
# helm
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" >/etc/apt/sources.list.d/helm-stable-debian.list \
  && curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor >/usr/share/keyrings/helm.gpg

# terraform
RUN release="$(awk -F= '/VERSION_CODENAME/ { print $2 }' /etc/os-release)" \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $release main" >/etc/apt/sources.list.d/hashicorp.list \
  && curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor >/usr/share/keyrings/hashicorp-archive-keyring.gpg

RUN apt-get update \
  && apt-get install --yes \
      helm \
      jq \
      terraform \
      unzip \
      wget \
      vim \
  && rm -rf /var/lib/apt/lists/*

RUN curl -L https://carvel.dev/install.sh \
  | bash

# aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf awscliv2.zip aws

# eks cli
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
  | tar xz -C /usr/local/bin
