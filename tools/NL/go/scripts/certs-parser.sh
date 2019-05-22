#!/bin/bash

#apt-get update
#apt-get install -y jq

echo "#####Creating MSP directory structure#####"
mkdir -p msp/admincerts
mkdir -p msp/cacerts
mkdir -p msp/signcerts
mkdir -p msp/tlscacerts
mkdir -p msp/keystore

mkdir tls

ADMINCERT=$(eval echo $(cat $MSP | jq '.msp.admin_certs.admin_pem'))
echo -e $ADMINCERT > msp/admincerts/cert.pem
CACERT=$(cat $MSP | jq '.msp.ca_certs.ca_pem' | tr -d \")
echo -e $CACERT > msp/cacerts/ca-cert.pem
SIGNCERT=$(cat $MSP | jq '.msp.sign_certs.pem' | tr -d \")
echo -e $SIGNCERT > msp/signcerts/cert.pem
TLSCACERT=$(cat $MSP | jq '.msp.tls_ca.tls_pem' | tr -d \")
echo -e $TLSCACERT > msp/tlscacerts/tlsca-cert.pem
PRIVKEY=$(cat $MSP | jq '.msp.key_store.private_key' | tr -d \")
echo -e $PRIVKEY > msp/keystore/cert.key
TLS_CA_CRT=$(cat $MSP | jq '.tls.ca_cert' | tr -d \")
echo -e $TLS_CA_CRT > tls/ca.crt
TLS_SERVER_CRT=$(cat $MSP | jq '.tls.server_cert' | tr -d \")
echo -e $TLS_SERVER_CRT > tls/server.crt
TLS_SERVER_KEY=$(cat $MSP | jq '.tls.server_key' | tr -d \")
echo -e $TLS_SERVER_CRT > tls/server.key
