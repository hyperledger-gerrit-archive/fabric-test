#!/bin/bash

. ./global_variable.sh
. ./helper_function.sh

testV10PubData() {
	echo -e "\n============================================================================"
	echo -e "                 Version 1.0 public data		                       "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.0) 1. Installing the marbles private chaincode  ===\n"
	SetEnv $ORG1
	peer chaincode install -n marbles -v 1.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles
	SetEnv $ORG2
	peer chaincode install -n marbles -v 1.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles

	echo -e "\n=== (v1.0) 2. Instantiating the marbles chaincode ===\n"
	SetEnv $ORG1
	peer chaincode instantiate -o $ORDERER $CHANNEL_AND_CHAINCODE_PUB -v 1.0  -c '{"Args":["init"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" 

	echo -e "\n=== (v1.0) 3. Quering for marble1 (which does not exist) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" "Marble does not exist: marble1"

	echo -e "\n=== (v1.0) 4. Storing (marble1,blue,100,tom) ===\n"
	SetEnv $ORG1
	peer chaincode invoke -o $ORDERER $CHANNEL_AND_CHAINCODE_PUB -c '{"Args":["initMarble","marble1","blue","100","tom"]}'

	echo -e "\n=== (v1.0) 5. Quering for marble1 on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.0) 6. Quering for marble1 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PUB" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'
}
