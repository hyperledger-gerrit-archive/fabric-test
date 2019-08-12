#!/bin/sh
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

if [ "$(which apt | wc -l)" = 1 ]
then
  apt-get update
  apt-get install -y jq
elif [ "$(which apk | wc -l)" = 1 ]
then
  apk add jq
fi

MSPDIR=/etc/hyperledger/fabric/artifacts/
MSPSECRET=/etc/hyperledger/fabric/secret/$1
set -e

echo "#####Creating MSP directory structure#####"
mkdir -p $MSPDIR/msp/admincerts $MSPDIR/msp/cacerts $MSPDIR/msp/signcerts $MSPDIR/msp/tlscacerts $MSPDIR/msp/keystore $MSPDIR/tls $MSPDIR/ca $MSPDIR/tlsca

ADMINCERT=$(eval echo "$(cat "$MSPSECRET" | jq '.msp.admin_pem')")
echo "$ADMINCERT" > $MSPDIR/msp/admincerts/cert.pem
sed -i '/^\s*$/d' $MSPDIR/msp/admincerts/cert.pem

CACERT=$(eval echo "$(cat "$MSPSECRET" | jq '.msp.ca_pem')")
echo "$CACERT" > $MSPDIR/msp/cacerts/ca-cert.pem
sed -i '/^\s*$/d' $MSPDIR/msp/cacerts/ca-cert.pem

SIGNCERT=$(eval echo "$(cat "$MSPSECRET" | jq '.msp.pem')")
echo "$SIGNCERT" > $MSPDIR/msp/signcerts/cert.pem
sed -i '/^\s*$/d' $MSPDIR/msp/signcerts/cert.pem

TLSCACERT=$(eval echo "$(cat "$MSPSECRET" | jq '.msp.tls_pem')")
echo "$TLSCACERT" > $MSPDIR/msp/tlscacerts/tlsca-cert.pem
sed -i '/^\s*$/d' $MSPDIR/msp/tlscacerts/tlsca-cert.pem

PRIVKEY=$(eval echo "$(cat "$MSPSECRET" | jq '.msp.private_key')")
echo "$PRIVKEY" > $MSPDIR/msp/keystore/cert.key
sed -i '/^\s*$/d' $MSPDIR/msp/keystore/cert.key

TLS_CA_CRT=$(eval echo "$(cat "$MSPSECRET" | jq '.tls.ca_cert')")
echo "$TLS_CA_CRT" > $MSPDIR/tls/ca.crt
sed -i '/^\s*$/d' $MSPDIR/tls/ca.crt

TLS_SERVER_CRT=$(eval echo "$(cat "$MSPSECRET" | jq '.tls.server_cert')")
echo "$TLS_SERVER_CRT" > $MSPDIR/tls/server.crt
sed -i '/^\s*$/d' $MSPDIR/tls/server.crt

TLS_SERVER_KEY=$(eval echo "$(cat "$MSPSECRET" | jq '.tls.server_key')")
echo "$TLS_SERVER_KEY" > $MSPDIR/tls/server.key
sed -i '/^\s*$/d' $MSPDIR/tls/server.key

CA_CRT=$(eval echo "$(cat "$MSPSECRET" | jq '.ca.pem')")
echo "$CA_CRT" > $MSPDIR/ca/ca-cert.pem
sed -i '/^\s*$/d' $MSPDIR/ca/ca-cert.pem

CA_PRIVATE_KEY=$(eval echo "$(cat "$MSPSECRET" | jq '.ca.private_key')")
echo "$CA_PRIVATE_KEY" > $MSPDIR/ca/ca_private.key
sed -i '/^\s*$/d' $MSPDIR/ca/ca_private.key

TLSCA_CRT=$(eval echo "$(cat "$MSPSECRET" | jq '.tlsca.pem')")
echo "$TLSCA_CRT" > $MSPDIR/tlsca/tlsca-cert.pem
sed -i '/^\s*$/d' $MSPDIR/tlsca/tlsca-cert.pem

TLSCA_PRIVATE_KEY=$(eval echo "$(cat "$MSPSECRET" | jq '.tlsca.private_key')")
echo "$TLSCA_PRIVATE_KEY" > $MSPDIR/tlsca/tlsca_private.key
sed -i '/^\s*$/d' $MSPDIR/tlsca/tlsca_private.key

echo "#####Completed creating MSP directory structure#####"

set +e