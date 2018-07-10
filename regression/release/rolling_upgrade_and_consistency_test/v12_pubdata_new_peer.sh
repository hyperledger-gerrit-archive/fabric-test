#!/bin/bash

. ./global_variable.sh
. ./helper_function.sh

testV12PubDataNewPeer() {
	echo -e "\n============================================================================"
	echo -e "                 Version 1.2 public data in the new peer                      "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.2 - new peer) 1. Installing the marbles private chaincode  ===\n"
	SetEnv $ORG2 "1"
	peer chaincode install -n marbles -v 1.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles

	echo -e "\n=== (v1.2 - new peer) 2. Quering for marble1 (which was stored by v1.0 network ) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}' "1"

	echo -e "\n=== (v1.2 - new peer) 3. Quering for marble2 (which was stored by v1.1 network ) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":200,"owner":"tom"}' "1" 

	echo -e "\n=== (v1.2 - new peer) 4. Quering for marble3 (which was stored by v1.2 network ) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":200,"owner":"tom"}' "1"
}
