#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

CERT_DIR="./"
SCRIPT_DIR="../../cert-templates"

if [ ! -d $CERT_DIR ]; then
  mkdir $CERT_DIR
fi
cd $CERT_DIR

PROVIDER_CA_KEY_NAME="provider-ca-key.pem"
PROVIDER_CA_CERT_NAME="provider-ca-crt.pem"
PROVIDER_CA_SRL_NAME="provider-ca-crt.srl"

CONSUMER_CA_KEY_NAME="consumer-ca-key.pem"
CONSUMER_CA_CERT_NAME="consumer-ca-crt.pem"
CONSUMER_CA_SRL_NAME="consumer-ca-crt.srl"

CA_CONF="$SCRIPT_DIR/ca.cnf"
TEMPLATE_CONF="$SCRIPT_DIR/template.cnf"
TEMP_DIR="$(mktemp -dt "$(basename "$0").XXXX")"

checkOpenSSL() {
  if test -z "$(type openssl)"; then
    echo "Requires openssl"
    exit 1
  fi
}

checkPassword() {
  if ! openssl rsa -in $CA_KEY_NAME -check -passin pass:$PASSWORD -noout | grep -q "RSA key ok"; then
    echo "Incorrect password."
    exit 1
  fi
}

generateCa() {
  openssl req -new -x509 -days 9999 -config "$CA_CONF" -keyout "$CA_KEY_NAME" -out "$CA_CERT_NAME"
}

getCaKey() {
  if test -f "$CA_KEY_NAME"; then
    echo "Using existing CA key"
    CA_KEY="$CA_KEY_NAME"
  else
    echo "Generating new CA key"
    generateCa
    getCaKey
  fi
}

getCaCert() {
  if test -f "$CA_CERT_NAME"; then
    echo "Using existing CA cert"
    CA_CERT="$CA_CERT_NAME"
  else
    echo "Generating new CA cert"
    generateCa
    getCaCert
  fi
}

getConfig() {
  local name=$1
  local config="$TEMP_DIR"/"$name".cnf
  cp "$TEMPLATE_CONF" "$config"
  sed -i.bak "s/{{name}}/localhost/g" "$config"
  rm -f *.bak
  echo "$config"
}

generateKeyAndCert() {

  # Generate private key
  local name=$1
  local key="$name"-key.pem
  openssl genrsa -out "$key" 4096

  # Generate Certificate Signing Request
  local config
  config="$(getConfig "$name")"

  local csr="$TEMP_DIR"/"$name"-csr.pem
  openssl req -new -config "$config" -key "$key" -out "$csr"

  openssl x509 -req -extfile "$config" \
    -days 999 -passin "pass:$PASSWORD" \
    -in "$csr" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$name"-crt.pem
}

generateKeysAndCerts() {

  if [ -z "$PASSWORD" ]; then
    echo 'Enter PEM pass phrase:'
    read -s PASSWORD
    checkPassword
  fi

  for ((i=$LEDGER_EX;i<$LEDGER_NUM+LEDGER_EX;i++)); do
    generateKeyAndCert "ledger$i-server"
  done

  if [[ $CONN_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "connector-server"
  fi

  if [[ $VALIDATOR_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "validator-server"
  fi

  if [[ $QUOTER_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "quoter-server"
  fi

  if [[ $RIPPLE_CONNECT_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "ripple-connect-server"
  fi

  if [[ $CONNECTOR_PROVIDER_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "provider-connector-account"
  fi

  if [[ $CONNECTOR_CONSUMER_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "consumer-connector-account"
  fi

  if [[ $TRANSACTIONAL_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "transactional-account"
  fi

  if [[ $ADMIN_REQ =~ ^([yY][eE][sS]|[yY])$ ]]; then
    generateKeyAndCert "admin"
  fi

  # cleanup
  if test -f $CA_SRL_NAME; then
    rm $CA_SRL_NAME
  fi

}

promptCustom() {
  read -rep "$LEDGER_EX "$'ledger cert/key pairs already exist. How many additional ledger certs are required?:\n' LEDGER_NUM
  read -rep $'Are connector certs required?:\n' CONN_REQ
  read -rep $'Are validator certs required?:\n' VALIDATOR_REQ
  read -rep $'Are quoter certs required?:\n' QUOTER_REQ
  read -rep $'Are Ripple Connect server certs required?:\n' RIPPLE_CONNECT_REQ
  read -rep $'Are connector liquidity provider account certs required?:\n' CONNECTOR_PROVIDER_REQ
  read -rep $'Are connector liquidity consumer account certs required?:\n' CONNECTOR_CONSUMER_REQ
  read -rep $'Are transactional account certs required?:\n' TRANSACTIONAL_REQ
  read -rep $'Are admin certs required?:\n' ADMIN_REQ
}

checkOpenSSL
echo 'Are you the liquidity provider or the liquidity consumer? This information is used to find or name your CA certs'
options=("Liquidity Provider"
         "Liquidity Consumer")
select opt in "${options[@]}"
do
  echo $opt
  case $opt in
    "Liquidity Provider")
        CA_CERT_NAME=$PROVIDER_CA_CERT_NAME
        CA_KEY_NAME=$PROVIDER_CA_KEY_NAME
        CA_SRL_NAME=$PROVIDER_CA_SRL_NAME
        break
        ;;
    "Liquidity Consumer")
        CA_CERT_NAME=$CONSUMER_CA_CERT_NAME
        CA_KEY_NAME=$CONSUMER_CA_KEY_NAME
        CA_SRL_NAME=$CONSUMER_CA_SRL_NAME
        break
        ;;
    *)
        echo "Invalid option"
        break
        ;;
  esac
done

getCaKey
getCaCert

echo 'Which certificates would you like generated: '
options=("Liquidity Provider Certificates"
         "Liquidity Consumer Certificates"
         "Custom"
         "Quit")
select opt in "${options[@]}"
do
  echo $opt
  case $opt in
    "Liquidity Provider Certificates")
        LEDGER_EX=0
        LEDGER_NUM=1
        CONN_REQ=y
        VALIDATOR_REQ=y
        QUOTER_REQ=y
        RIPPLE_CONNECT_REQ=y
        CONNECTOR_PROVIDER_REQ=y
        CONNECTOR_CONSUMER_REQ=n
        TRANSACTIONAL_REQ=y
        ADMIN_REQ=y
        generateKeysAndCerts
        break
        ;;
    "Liquidity Consumer Certificates")
        LEDGER_EX=0
        LEDGER_NUM=1
        CONN_REQ=n
        VALIDATOR_REQ=n
        QUOTER_REQ=n
        RIPPLE_CONNECT_REQ=y
        CONNECTOR_PROVIDER_REQ=n
        CONNECTOR_CONSUMER_REQ=y
        TRANSACTIONAL_REQ=y
        ADMIN_REQ=y
        generateKeysAndCerts
        break
        ;;
    "Custom")
        LEDGER_FILES=$(ls $CERT_DIR/ledger* 2>/dev/null | wc -l)
        LEDGER_EX=$(($LEDGER_FILES / 2))
        promptCustom
        generateKeysAndCerts
        break
        ;;
    "Quit")
        break
        ;;
    *)
        echo "Invalid option"
        break
        ;;
  esac
done
