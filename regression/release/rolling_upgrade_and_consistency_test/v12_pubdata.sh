#!/bin/bash

. ./global_variable.sh
. ./helper_function.sh

testV12PubData() {
	echo -e "\n============================================================================"
	echo -e "                 Version 1.2 public data		                       "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.2) 1. Quering for marble1 (which was stored by v1.0 network ) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.2) 2. Quering for marble1 (which was stored by v1.0 network ) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.2) 3. Quering for marble2 (which was stored by v1.1 network ) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.2) 4. Quering for marble2 (which was stored by v1.1 network ) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":200,"owner":"tom"}'

	echo -e "\n=== (v1.2) 5. Quering for marble3 (which does not exist) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble3" "Marble does not exist: marble3"

	echo -e "\n=== (v1.2) 6. Storing (marble3,red,300,tom) ===\n"
	SetEnv $ORG1
	peer chaincode invoke -o $ORDERER $CHANNEL_AND_CHAINCODE_PUB -c '{"Args":["initMarble","marble3","red","300","tom"]}'

	echo -e "\n=== (v1.2) 7. Quering for marble3 on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble3" '{"docType":"marble","name":"marble3","color":"red","size":300,"owner":"tom"}'

	echo -e "\n=== (v1.2) 8. Quering for marble3 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble3" '{"docType":"marble","name":"marble3","color":"red","size":300,"owner":"tom"}'
}
