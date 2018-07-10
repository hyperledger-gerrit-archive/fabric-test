#!/bin/bash
<< HOW_TO_RUN_THIS_TEST
To run the test, do the following
(a) If any changes had been made to local master branch,
    please commit those changes.
(b) Install jq
	ubuntu -- apt-get intall jq
	mac    -- brew install jq
(e) cd examples/e2e_cli/manual_test &&
		./rolling_upgrade_pvtdata_test.sh
HOW_TO_RUN_THIS_TEST

<< SCENARIO
(1) There are two organization: Org1 and Org2. One peer per
    organization and one orderer for the whole network.
    Instead of docker containers for peers/orderers, we
    use native binaries.
(2) The marbles_private chaincode is used througout.
(3) Start the network using fabric v1.1 executables without
    private data capability to ensure that collections
    definition are not allowed during chaincode instantiation
(4) Enable private data capability to ensure that collections
    definition are allowed
(5) Invoke and Query private data
(6) Upgrade the network to v1.2 without enabling v12 capability
    to ensure that collection upgrades are not allowed during
    chaincode upgrade
(7) Query private data stored with v1.1 network
(8) Enable v12 capability to ensure that collections upgrades
    are allowed during chaincode upgrade
(9) Invoke and Query private data
SCENARIO

TEST_TYPE="pvtdata_rolling_upgrade"

. ./global_variable.sh
. ./helper_function.sh
. ./v11_pvtdata.sh
. ./v12_pvtdata.sh

echo -e "\n=== (master) 1. Stopping peer and orderer executables from the last run if any ===\n"
stopPeersAndOrderers

echo -e "\n=== (master) 2. Removing ledgerData, msp, and tls certs created during the last run ===\n"
sh cleanup.sh ""

echo -e "\n=== (master) 3. Checkout fabric v1.1 and compile to create binary and docker images ===\n"
checkoutFabricAndCompile release-1.1
cpExecutables "Version: 1.1"
cpConfig v1.1

echo -e "\n=== (master) 4. Generating artifacts ===\n"
generateArtifacts $TEST_TYPE "v1.1" 

echo -e "\n=== (master) 5. Starting the org1 peer, org2 peer, and an orderer node using v1.1 executables ===\n"
startPeersAndOrderers

echo -e "\n=== (master) 6. Setting up the channel ch1 ===\n"
setupChannel

echo -e "\n=== (master) 7. Testing private data with V1.1 network ===\n"
testV11PvtData

echo -e "\n=== (master) 8. Stopping the peer and orderer in v1.1 network ===\n"
stopPeersAndOrderers

echo -e "\n=== (master) 9. Removing the chaincode container and images ===\n"
docker ps --all | grep marbles_private | awk '{print $1}' | xargs docker rm -f
docker images | grep marbles_private | awk '{print $3}' | xargs docker rmi

echo -e "\n=== (master) 10. Checkout fabric master and compile to create binary and docker images ===\n"
checkoutFabricAndCompile master
cpExecutables "Version: 1.2"
cpConfig v1.2

echo -e "\n=== (master) 11. Starting the org1 peer, org2 peer, and an orderer node using v1.2 executables ===\n"
startPeersAndOrderers

echo -e "\n=== (master) 12. Testing private data with V1.2 network ===\n"
testV12PvtData
