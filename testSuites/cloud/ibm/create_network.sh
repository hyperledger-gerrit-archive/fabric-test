#!/bin/bash

if [ -z $1 -o -z $2 ]; then
  echo "===== ERROR:  Must pass the API Key and ORG name ===="
  exit 1
fi

rm -rf ./creds
mkdir -p creds

BX_API_KEY=$1
BX_ORG=$2
BX_SPACE=dev
BX_API_ENDPOINT=https://api.ng.bluemix.net

INSTANCE_NAME=Blockchain-$RANDOM
BX_SERVICE_NAME=ibm-blockchain-5-prod
BX_SERVICE_PLAN=ibm-blockchain-plan-v1-ga1-starter-prod
SERVICE_KEY=service_key

## disable update check
bx config --check-version=false

# login to ibm cloud
bx api ${BX_API_ENDPOINT}

# bx login
bx login --apikey ${BX_API_KEY}

# bx target -o ${BX_ORG} -s ${BX_SPACE}
bx target --cf-api ${BX_API_ENDPOINT} -o ${BX_ORG} -s ${BX_SPACE}

# create a new blockchain starter
bx service create ${BX_SERVICE_NAME} ${BX_SERVICE_PLAN} ${INSTANCE_NAME}

echo ${INSTANCE_NAME} >> creds/instance_name

bx service key-create ${INSTANCE_NAME} ${SERVICE_KEY}
bx service key-show ${INSTANCE_NAME} ${SERVICE_KEY} | tail -n +5 > network.json

echo " ========= Network got created ========"
echo
echo
