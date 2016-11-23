#!/usr/bin/env bash

set -eo pipefail

CA_KEY="ca-key.pem"
CA_CERT="ca-crt.pem"
CA_CONF="ca.cnf"
TEMPLATE_CONF="template.cnf"
TEMP_DIR="$(mktemp -dt "$(basename "$0")")"

checkOpenSSL() {
  if test -z "$(type openssl)"; then
    echo "Requires openssl"
    exit 1
  fi
}

generateCa() {
  openssl req -new -x509 -days 9999 -config "$CA_CONF" -keyout "$CA_KEY" -out "$CA_CERT"
}

getCaKey() {
  if test -f "$CA_KEY"; then
    echo "$CA_KEY"
  else
    generateCa
    getCaKey
  fi
}

getCaCert() {
  if test -f "$CA_CERT"; then
    echo "$CA_CERT"
  else
    generateCa
    getCaCert
  fi
}

getConfig() {
  local name=$1
  local config="$TEMP_DIR"/"$name".cnf
  cp "$TEMPLATE_CONF" "$config"
  sed -i.bak "s/{{name}}/$name/g" "$config"
  rm -f *.bak
  echo "$config"
}

generateKeysAndCerts() {

  # Generate private key
  local name=$1
  local key="$name"-key.pem
  openssl genrsa -out "$key" 4096

  # Generate Certificate Signing Request
  local config
  config="$(getConfig "$name")"

  local csr="$TEMP_DIR"/"$name"-csr.pem
  openssl req -new -config "$config" -key "$key" -out "$csr"

  # Generate signed public certificate
  local caKey
  local caCert
  caKey="$(getCaKey)"
  caCert="$(getCaCert)"

  openssl x509 -req -extfile "$config" \
    -days 999 -passin "pass:password" \
    -in "$csr" \
    -CA "$caCert" \
    -CAkey "$caKey" \
    -CAcreateserial \
    -out "$name"-crt.pem
}

main() {
  checkOpenSSL
  generateKeysAndCerts "ledger"
  generateKeysAndCerts "connector"
  generateKeysAndCerts "notary"
  generateKeysAndCerts "quoter"
  generateKeysAndCerts "alice"
  generateKeysAndCerts "bob"
  generateKeysAndCerts "admin"
}

main
