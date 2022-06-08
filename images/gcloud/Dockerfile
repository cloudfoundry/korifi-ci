FROM google/cloud-sdk

ARG TERRAFORM_VERSION=1.2.2
ARG HELM_VERSION=v3.9.0

RUN apt-get update && \
    apt-get install --yes \
      jq \
      unzip \
      wget \
      vim \
  && rm -rf /var/lib/apt/lists/*

RUN curl -L https://k14s.io/install.sh | bash

RUN wget --quiet https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && tar xfz helm-${HELM_VERSION}-linux-amd64.tar.gz && mv linux-amd64/helm /usr/bin/ && chmod +x /usr/bin/helm

RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
      && mv terraform /usr/local/bin/ \
      && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
