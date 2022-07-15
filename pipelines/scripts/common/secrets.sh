CERT_MANAGER_NAMESPACE=cert-manager
WILDCARD_CERT_NAME=cluster-wildcard-cert

function create_tls_secret() {
  local secret_name=${1:?}
  local secret_namespace=${2:?}
  local tls_cn=${3:?}

  tmp_dir=$(mktemp -d -t cf-tls-XXXXXX)
  trap "rm -rf $tmp_dir" EXIT

  openssl req -x509 -newkey rsa:4096 \
    -keyout ${tmp_dir}/tls.key \
    -out ${tmp_dir}/tls.crt \
    -nodes \
    -subj "/CN=${tls_cn}" \
    -extensions SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[ SAN ]\nsubjectAltName='DNS:${tls_cn}'")) \
    -days 365

  cat <<EOF >${tmp_dir}/kustomization.yml
secretGenerator:
- name: ${secret_name}
  namespace: ${secret_namespace}
  files:
  - tls.crt=tls.crt
  - tls.key=tls.key
  type: "kubernetes.io/tls"
generatorOptions:
  disableNameSuffixHash: true
EOF

  kubectl apply -k $tmp_dir
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

    kubectl -n "$CERT_MANAGER_NAMESPACE" wait --for=condition=Ready "certificate/$WILDCARD_CERT_NAME"
  fi
}
