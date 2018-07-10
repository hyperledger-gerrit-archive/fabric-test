#!/bin/bash

. ./global_variable.sh
. ./helper_function.sh

testV12PvtDataNewPeer() {
	echo -e "\n=== (v1.2 - new peer) 1. Installing the marble_private chaincode version 2.0 ===\n"
	SetEnv $ORG2 "1"
	peer chaincode install -n marbles_private -v 2.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles_private


	echo -e "\n=== (v1.2 - new peer) 2. Quering for marble1 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}' "1"

	echo -e "\n=== (v1.2 - new peer) 3. Quering for marble1 private details (which does not exist) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble1" 'Failed to get private details for marble1' "1"

	echo -e "\n=== (v1.2 - new peer) 4. Quering for marble2 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":100,"owner":"tom"}' "1"

	echo -e "\n=== (v1.2 - new peer) 5. Quering for marble2 private details on org2 (newly added member to the private collection) ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble2" '{"docType":"marblePrivateDetails","name":"marble2","price":250}' "1"
}






