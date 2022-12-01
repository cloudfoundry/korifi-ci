FROM google/cloud-sdk

ARG TERRAFORM_VERSION=1.2.2
ARG HELM_VERSION=v3.9.0

ENV USE_GKE_GCLOUD_AUTH_PLUGIN=True

RUN apt-get update && \
    apt-get install --yes \
      jq \
      unzip \
      wget \
      vim \
      google-cloud-sdk-gke-gcloud-auth-plugin \
  && rm -rf /var/lib/apt/lists/*

RUN curl -L https://carvel.dev/install.sh | bash

RUN wget --quiet https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && tar xfz helm-${HELM_VERSION}-linux-amd64.tar.gz && mv linux-amd64/helm /usr/bin/ && chmod +x /usr/bin/helm

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      && mv terraform /usr/local/bin/ \
      && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install \
  && rm -rf awscliv2.zip aws
