#!/bin/bash


SetEnv() {
	ORGID=$1

	if [ "$#" -eq "2" ]; then
		PEERID=$2
	else 
		PEERID=0
	fi

	PORT_INCR=$((1000 * (ORGID - 1)))
	PORT=$((7051 + PORT_INCR))
	export FABRIC_CFG_PATH=org${ORGID}_peer0
	export CORE_PEER_LOCALMSPID="Org${ORGID}MSP"
	export CORE_PEER_MSPCONFIGPATH=../config/crypto-config/peerOrganizations/org${ORGID}/users/Admin@org${ORGID}/msp
	export CORE_PEER_ADDRESS=localhost:$PORT

	if [ $PEERID = "1" ]; then
		export FABRIC_CFG_PATH=org${ORGID}_peer1
		export CORE_PEER_ADDRESS=localhost:9051
	fi
}

SetOrdererEnv() {
	export FABRIC_CFG_PATH=orderer
	export CORE_PEER_LOCALMSPID="OrdererOrg0MSP"
	export CORE_PEER_MSPCONFIGPATH=../config/crypto-config/ordererOrganizations/ordererorg0/users/Admin@ordererorg0/msp
}

checkoutFabricAndCompile() {
	BRANCH=$1
	pushd $GOPATH/src/github.com/hyperledger/fabric
	git checkout $BRANCH
	git pull
	rm -rf build .build
	make docker-clean 1> /dev/null 2> /dev/null
	#ccenv docker image is required to build the chaincode
	echo -e "\n == please WAIT for 'make native ccenv' to complete == \n"
	make native ccenv 1> compile_logs.txt
	popd
}

cpExecutables() {
	mkdir executables

	EXPECTED_RESULT=$1
	pushd $GOPATH/src/github.com/hyperledger/fabric
	
	[ -d "build" ] && cp build/bin/* examples/e2e_cli/manual_test/executables
	[ -d ".build" ] && cp .build/bin/* examples/e2e_cli/manual_test/executables

	export PATH=$PATH:$GOPATH/src/github.com/hyperledger/fabric/examples/e2e_cli/manual_test/executables
	FABRIC_CFG_PATH=sampleconfig/ CORE_PEER_MSPCONFIGPATH=msp peer version >&log.txt

	VALUE="$(cat log.txt | grep -q "$EXPECTED_RESULT" && echo "$EXPECTED_RESULT")"
	rc=1
	test "${VALUE}" = "${EXPECTED_RESULT}" && let rc=0
	if test $rc -ne 0 ; then
		cat log.txt
		echo "!!!!!!!!!!!!!!! Either a problem in compilation or a correct path in not set to find the executable !!!!!!!!!!!!!!!!"
		echo "================== ERROR =================="
		echo
		exit 1
	fi

	popd
}

cpConfig() {
	VERSION=$1
	cp org1_peer0/$VERSION/core.yaml org1_peer0/
	cp org2_peer0/$VERSION/core.yaml org2_peer0/
	cp orderer/$VERSION/core.yaml orderer/
	cp orderer/$VERSION/orderer.yaml orderer/
}

generateArtifacts() {
	TEST_TYPE=$1
	VERSION=$2
	echo -e "\na) Creating Crypto Materials ===\n"
	pushd config > /dev/null
	rm -rf crypto-config ch1.tx Org1MSPanchors.tx Org2MSPanchors.tx genesis.block
	cryptogen generate --config=crypto-config.yaml

	echo -e "\nb) Copying the crypto materials to peer and orderer config path ===\n"
	cp -r crypto-config/peerOrganizations/org1/peers/peer0.org1/msp ../org1_peer0
	cp -r crypto-config/peerOrganizations/org1/peers/peer0.org1/tls ../org1_peer0
	cp -r crypto-config/peerOrganizations/org2/peers/peer0.org2/msp ../org2_peer0
	cp -r crypto-config/peerOrganizations/org2/peers/peer0.org2/tls ../org2_peer0

	if [ $TEST_TYPE = "add_a_new_peer" ]; then 
		cp -r crypto-config/peerOrganizations/org2/peers/peer1.org2/msp ../org2_peer1
		cp -r crypto-config/peerOrganizations/org2/peers/peer1.org2/tls ../org2_peer1
	fi

	cp -r crypto-config/ordererOrganizations/ordererorg0/orderers/orderer.ordererorg0/msp ../orderer/
	cp -r crypto-config/ordererOrganizations/ordererorg0/orderers/orderer.ordererorg0/tls ../orderer/

	if [ $VERSION = "v1.0" ]; then 
		cp v1.0/configtx.yaml ./
	elif [ $VERSION = "v1.1" ]; then
		cp v1.1/configtx.yaml ./
	fi

	echo -e "\nc). Creating orderer genesis block ===\n"
	export FABRIC_CFG_PATH=./
	configtxgen -profile TwoOrgsOrdererGenesis -outputBlock genesis.block

	echo -e "\nd) Creating channel tx ===\n"
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./ch1.tx -channelID ch1

	echo -e "\ne) Creating tx to update anchor peers ===\n"
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org1MSPanchors.tx -channelID ch1 -asOrg Org1MSP
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./Org2MSPanchors.tx -channelID ch1 -asOrg Org2MSP
	popd > /dev/null
}

setupChannel() {
	echo -e "\na) Creating the channel genesis block ===\n"
	SetEnv $ORG1
	peer channel create -o $ORDERER -c ch1 -f config/ch1.tx

	echo -e "\nb) Joining peer0.org1 to channel ch1  ===\n"
	SetEnv $ORG1
	peer channel join -b ch1.block

	echo -e "\nc) Joining peer0.org2 to channel ch1  ===\n"
	SetEnv $ORG2
	peer channel join -b ch1.block

	echo -e "\nd) Setting anchor peer for org1 ===\n"
	SetEnv $ORG1
	peer channel update -o $ORDERER -c ch1 -f config/Org1MSPanchors.tx

	echo -e "\ne) Setting anchor peer for org2 ===\n"
	SetEnv $ORG2
	peer channel update -o $ORDERER -c ch1 -f config/Org2MSPanchors.tx
}

startPeersAndOrderers() {
	#Starting the org1 peer
	export CORE_PEER_LOCALMSPID=Org1MSP
	export CORE_PEER_MSPCONFIGPATH=msp
	screen -dmS org1_peer0 bash -c "FABRIC_CFG_PATH=org1_peer0 peer node start >> log_org1_peer0.txt 2>&1"

	#Starting the org2 peer
	export CORE_PEER_LOCALMSPID=Org2MSP
	export CORE_PEER_ADDRESS=localhost:8051
	screen -dmS org2_peer0 bash -c "FABRIC_CFG_PATH=org2_peer0 peer node start >> log_org2_peer0.txt 2>&1"

	#Starting the orderer0
	screen -dmS orderer0 bash -c "FABRIC_CFG_PATH=orderer ORDERER_GENERAL_GENESISMETHOD=file ORDERER_GENERAL_GENESISFILE=$PWD/config/genesis.block orderer >> log_orderer.txt 2>&1"

	sleep 5
}

stopPeersAndOrderers() {
	pkill peer
	pkill orderer
	pkill screen
}

updateCapabilities() {
	CAPABILITIES=$1
	GROUP=$2
	ORDERER_NODE=$3

	echo -e "\na) Fetching the channel config block\n"
	SetEnv $ORG1
	peer channel fetch config config_block.pb -o $ORDERER_NODE -c ch1

	echo -e "\nb) Decoding the config block\n"
	configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
	jq .data.data[0].payload.data.config config_block.json > config.json

	echo -e "\nc) Setting Capability\n"
	if [ $GROUP = "channel" ]; then
		jq -s '.[0] * {"channel_group":{"values": {"Capabilities": .[1]}}}' config.json $CAPABILITIES > modified_config.json
	elif [ $GROUP = "application" ]; then
		jq -s '.[0] * {"channel_group":{"groups":{"Application": {"values": {"Capabilities": .[1]}}}}}' config.json $CAPABILITIES > modified_config.json
	elif [ $GROUP = "orderer" ]; then 
                jq -s '.[0] * {"channel_group":{"groups":{"Orderer": {"values": {"Capabilities": .[1]}}}}}' config.json $CAPABILITIES >  modified_config.json
	fi
<<CC
	if [ $CAPABILITIES = "./capabilities/v12.json" ]; then
		sed '/"V1_1": {},/d' modified_config.json > modified_config_rm_old_v11.json
		sed '/"V1_1_PVTDATA_EXPERIMENTAL": {},/d' modified_config_rm_old_v11.json > modified_config.json
	fi
CC
	echo -e "\nd) Creating a channel upgrade tx\n"
	configtxlator proto_encode --input config.json --type common.Config --output config.pb
	configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
	configtxlator compute_update --channel_id ch1 --original config.pb --updated modified_config.pb --output config_update.pb
	configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
	echo '{"payload":{"header":{"channel_header":{"channel_id":"ch1", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
	configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

	echo -e "\ne) Getting signature from all orgs and submitting the channel upgrade tx"
	if [ $GROUP = "application" ]; then
		SetEnv $ORG1
		peer channel signconfigtx -f config_update_in_envelope.pb
		SetEnv $ORG2
		peer channel update -f config_update_in_envelope.pb -c ch1 -o $ORDERER_NODE
	elif [ $GROUP = "channel" ]; then
		SetEnv $ORG1
		peer channel signconfigtx -f config_update_in_envelope.pb
		SetEnv $ORG2
		peer channel signconfigtx -f config_update_in_envelope.pb
		SetOrdererEnv
		peer channel update -f config_update_in_envelope.pb -c ch1 -o $ORDERER_NODE
	elif [ $GROUP = "orderer" ]; then
		SetOrdererEnv
		peer channel update -f config_update_in_envelope.pb -c ch1 -o $ORDERER_NODE
	fi

	rm *.pb *.json

	echo -e "\nf) sleep for 5 seconds to ensure that channel configs are updated on all peers\n"
	sleep 5
}

chaincodeQuery () {
	ORGID=$1
	CHANNEL_AND_CHAINCODE=$2
	FUNC=$3
	MARBLE=$4
	EXPECTED_RESULT=$5
	if [ "$#" -eq "6" ]; then
		PEERID=$6
	else 
		PEERID="0"
	fi

	SetEnv $ORGID $PEERID
	local rc=1
	local starttime=$(date +%s)

	# continue to poll
	# we either get a successful response, or reach TIMEOUT
	while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
	do
        	sleep 3
        	peer chaincode query $CHANNEL_AND_CHAINCODE -c '{"Args":["'$FUNC'","'$MARBLE'"]}' >&log.txt
        	VALUE="$(cat log.txt | grep -q "$EXPECTED_RESULT" && echo "$EXPECTED_RESULT")"
        	test "${VALUE}" = "${EXPECTED_RESULT}" && let rc=0
	done
	cat log.txt | grep "$EXPECTED_RESULT"
	if test $rc -ne 0 ; then
		cat log.txt
		echo "!!!!!!!!!!!!!!! Query result on peer0.org${ORGID} is INVALID !!!!!!!!!!!!!!!!"
        	echo "================== ERROR =================="
		echo
		exit 1
    	fi
}
