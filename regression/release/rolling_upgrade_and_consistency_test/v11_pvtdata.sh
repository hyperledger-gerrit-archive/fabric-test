#!/bin/bash

. ./global_variable.sh
. ./helper_function.sh

testV11PvtData() {
	echo -e "\n============================================================================"
	echo -e "                 Version 1.1 without private data capability                  "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.1) 1. Installing the marbles private chaincode  ===\n"
	SetEnv $ORG1
	peer chaincode install -n marbles_private -v 1.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles_private
	SetEnv $ORG2
	peer chaincode install -n marbles_private -v 1.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles_private


	echo -e "\n=== (v1.1) 2. Instantiating the marbles private chaincode without enabling PVTDATA feature ===\n"
	SetEnv $ORG1
	rc=1
	peer chaincode instantiate -o $ORDERER $CHANNEL_AND_CHAINCODE_PVT -v 1.0  -c '{"Args":["init"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" --collections-config chaincodes/marbles_private/collections-v1.0.json >&log.txt
	EXPECTED_RESULT="invalid number of argument to lscc 7"
	VALUE="$(cat log.txt | grep -q "$EXPECTED_RESULT" && echo "$EXPECTED_RESULT")"
	echo $VALUE
	test "${VALUE}" = "${EXPECTED_RESULT}" && let rc=0
	if test $rc -ne 0 ; then
		echo "!!!!!!!!!!!!!!! Instantiation should have failed as PVTDATA feature is not enabled and collection config is passed as an argument !!!!!!!!!!!!!!!!"
		echo "================== ERROR =================="
		echo
		exit 1
	fi

	echo -e "\n============================================================================"
	echo -e "                 Version 1.1 with private data capability                  "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.1) 3. Enable PVTDATA Ccapability ===\n"
	updateCapabilities ./capabilities/v11_pvtdata.json application $ORDERER

	echo -e "\n=== (v1.1) 4. Instantiating the marbles private chaincode after enabling PVTDATA feature ===\n"
	SetEnv $ORG1
	peer chaincode instantiate -o $ORDERER $CHANNEL_AND_CHAINCODE_PVT -v 1.0  -c '{"Args":["init"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" --collections-config chaincodes/marbles_private/collections-v1.0.json

	echo -e "\n=== (v1.1) 5. Quering for marble1 (which does not exist) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble1" "Marble does not exist: marble1"

	echo -e "\n=== (v1.1) 6. Storing (marble1,blue,100,tom,150) ===\n"
	SetEnv $ORG1
	peer chaincode invoke -o $ORDERER $CHANNEL_AND_CHAINCODE_PVT -c '{"Args":["initMarble","marble1","blue","100","tom","150"]}'

	echo -e "\n=== (v1.1) 7. Quering for marble1 on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.1) 8. Quering for marble1 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.1) 9. Quering for marble1 private details on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble1" '{"docType":"marblePrivateDetails","name":"marble1","price":150}'

	echo -e "\n=== (v1.1) 10. Quering for marble1 private details (which does not exist) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble1" 'Failed to get private details for marble1'
}
