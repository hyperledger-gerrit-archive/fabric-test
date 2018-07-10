#!/bin/bash

. ./global_variable.sh
. ./helper_function.sh

testV12PvtData() {

	echo -e "\n============================================================================"
	echo -e " Version 1.2 without v12 application capability but private data capability   "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.2) 1. Quering for marble1 on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.2) 2. Quering for marble1 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble1" '{"docType":"marble","name":"marble1","color":"blue","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.2) 3. Quering for marble1 private details on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble1" '{"docType":"marblePrivateDetails","name":"marble1","price":150}'

	echo -e "\n=== (v1.2) 4. Quering for marble1 private details (which does not exist) on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble1" 'Failed to get private details for marble1'

	echo -e "\n=== (v1.2) 5. Installing the marble_private chaincode version 2.0 ===\n"
	sleep 2
	SetEnv $ORG1
	peer chaincode install -n marbles_private -v 2.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles_private
	SetEnv $ORG2
	peer chaincode install -n marbles_private -v 2.0 -p github.com/hyperledger/fabric/examples/e2e_cli/manual_test/chaincodes/marbles_private

	#Commentted out due to a pending CR on lscc
	echo -e "\n=== (v1.2) 6. Upgrading the marbles private chaincode and collection config without enabling V12 capability ===\n"
	SetEnv $ORG1
	rc=1
	peer chaincode upgrade -o $ORDERER $CHANNEL_AND_CHAINCODE_PVT -v 2.0  -c '{"Args":["init"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" --collections-config chaincodes/marbles_private/collections-v2.0.json >&log.txt
	EXPECTED_RESULT="as V1_2 capability is not enabled, collection upgrades are not allowed"
	VALUE="$(cat log.txt | grep -q "$EXPECTED_RESULT" && echo "$EXPECTED_RESULT")"
	echo $VALUE
	test "${VALUE}" = "${EXPECTED_RESULT}" && let rc=0
	if test $rc -ne 0 ; then
		cat log.txt
		echo "!!!!!!!!!!!!!!! Upgrading should have failed as collection upgrade feature is not enabled and collection config is passed as an argument !!!!!!!!!!!!!!!!"
		echo "================== (v1.2) ERROR =================="
		echo
		exit 1
	fi

	echo -e "\n============================================================================"
	echo -e "                   Version 1.2 with v12 application capability                "
	echo -e "============================================================================\n"

	echo -e "\n=== (v1.2) 7. Enable v12 application capability ===\n"
	updateCapabilities ./capabilities/v12.json application $ORDERER
	#updateCapabilities ./capabilities/v12.json channel $ORDERER

	echo -e "\n=== (v1.2) 8. Upgrading the marbles private chaincode and collection config after enabling V12 capability ===\n"
	SetEnv $ORG1
	peer chaincode upgrade -o $ORDERER $CHANNEL_AND_CHAINCODE_PVT -v 2.0  -c '{"Args":["init"]}' -P "OR ('Org1MSP.member','Org2MSP.member')" --collections-config chaincodes/marbles_private/collections-v2.0.json

	echo -e "\n=== (v1.2) 9. Quering for marble2 (which does not exist) on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble2" "Marble does not exist: marble2"

	echo -e "\n=== (v1.2) 10. Storing (marble2,red,100,tom,250) ===\n"
	SetEnv $ORG1
	peer chaincode invoke -o $ORDERER $CHANNEL_AND_CHAINCODE_PVT -c '{"Args":["initMarble","marble2","red","100","tom","250"]}'

	echo -e "\n=== (v1.2) 11. Quering for marble2 on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.2) 12. Quering for marble2 on org2 ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarble" "marble2" '{"docType":"marble","name":"marble2","color":"red","size":100,"owner":"tom"}'

	echo -e "\n=== (v1.2) 13. Quering for marbler2 private details on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble2" '{"docType":"marblePrivateDetails","name":"marble2","price":250}'

	echo -e "\n=== (v1.2) 14. Quering for marble1 private details on org1 ===\n"
	chaincodeQuery $ORG1 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble1" '{"docType":"marblePrivateDetails","name":"marble1","price":150}'

	echo -e "\n=== (v1.2) 15. Quering for marble2 private details on org2 (newly added member to the private collection) ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble2" '{"docType":"marblePrivateDetails","name":"marble2","price":250}'

	echo -e "\n=== (v1.2) 16. Quering for marble1 private details on org2 (was not a member of the private collection when marble1 was added) ===\n"
	chaincodeQuery $ORG2 "$CHANNEL_AND_CHAINCODE_PVT" "readMarblePrivateDetails" "marble1" 'Failed to get private details for marble1'
}
