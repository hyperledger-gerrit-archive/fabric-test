#!/bin/bash

. ./global_variable.sh
. ./helper_function.sh

testV11PubData() {
	echo -e "\n============================================================================"
	echo -e "                 Version 1.1 public data		                       "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.1) 1. Quering for marble1 (which was stored by v1.0 network ) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.1) 2. Quering for marble1 (which was stored by v1.0 network ) on org1 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.1) 3. Quering for marble2 (which does not exist) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble2" "Marble does not exist: marble2"

	echo -e "\n=== (v1.1) 4. Storing (marble2,red,200,tom) ===\n"
	SetEnv $ORG1
	peer chaincode invoke -o $ORDERER $CHANNEL_AND_CHAINCODE_PUB -c '{"Args":["initMarble","marble2","red","200","tom"]}'

	echo -e "\n=== (v1.1) 5. Quering for marble2 on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":200,"owner":"tom"}'

	echo -e "\n=== (v1.1) 6. Quering for marble2 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":200,"owner":"tom"}'
}
