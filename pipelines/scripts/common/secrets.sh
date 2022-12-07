#!/bin/bash

CERT_MANAGER_NAMESPACE=cert-manager
WILDCARD_CERT_NAME=cluster-wildcard-cert

function clone_letsencrypt_cert() {
  local secret_name=${1:?}
  local secret_namespace=${2:?}

  kubectl -n "$CERT_MANAGER_NAMESPACE" get secret "$WILDCARD_CERT_NAME" -o yaml |
    yq 'del( .metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.selfLink, .metadata.namespace )' |
    yq ".metadata.name = \"$secret_name\"" |
    kubectl apply --namespace="$secret_namespace" -f -
}

function ensure_letsencrypt_issuer() {
  local dns_secret=clouddns-dns01-solver-svc-acct

  if ! kubectl get secret -n "$CERT_MANAGER_NAMESPACE" "$dns_secret"; then
    key_file=$(mktemp)
    trap "rm -f $key_file" EXIT
    echo "$DNS_SERVICE_ACCOUNT_JSON" >"$key_file"
    kubectl create secret -n "$CERT_MANAGER_NAMESPACE" generic "$dns_secret" --from-file=key.json="$key_file"
  fi

  if ! kubectl get issuer -n "$CERT_MANAGER_NAMESPACE" letsencrypt; then
    cat <<EOF | kubectl apply -n "$CERT_MANAGER_NAMESPACE" -f-
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt
spec:
  acme:
    email: korifi@cloudfoundry.org
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-private-key
    solvers:
      - dns01:
          cloudDNS:
            # The ID of the GCP project
            project: "$GCP_PROJECT_ID"
            # This is the secret used to access the service account
            serviceAccountSecretRef:
              name: clouddns-dns01-solver-svc-acct
              key: key.json
EOF
  fi
}

function ensure_domain_wildcard_cert() {
  if ! kubectl get certificate -n "$CERT_MANAGER_NAMESPACE" cluster-wildcard-cert; then
    cat <<EOF | kubectl apply -n "$CERT_MANAGER_NAMESPACE" -f-
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: $WILDCARD_CERT_NAME
spec:
  secretName: cluster-wildcard-cert
  commonName: $CLUSTER_NAME.korifi.cf-app.com
  dnsNames:
  - "*.$CLUSTER_NAME.korifi.cf-app.com"
  - "$CLUSTER_NAME.korifi.cf-app.com"
  issuerRef:
    name: letsencrypt
EOF

    kubectl -n "$CERT_MANAGER_NAMESPACE" wait \
      --for=condition=Ready=True \
      --timeout=5m \
      "certificate/$WILDCARD_CERT_NAME"
  fi
}
