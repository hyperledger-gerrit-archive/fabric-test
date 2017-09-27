#!/bin/bash

FabricTestDir=$GOPATH/src/github.com/hyperledger/fabric-test
#NLDir=$FabricTestDir/tools/NL
#PTEDir=$FabricTestDir/tools/PTE
SDKDir=$FabricTestDir/fabric-sdk-node

# PTE: create/join channel, install/instantiate chaincode
CWD=$PWD

cd $SDKDir/test/PTE

echo "[test_channel.sh] create channel"
./pte_driver.sh CITest/preconfig/runCases-chan-create-TLS.txt
sleep 60s

echo "[test_channel.sh] join channel"
./pte_driver.sh CITest/preconfig/runCases-chan-join-TLS.txt
sleep 20s

echo "[test_channel.sh] install chaincode"
./pte_driver.sh CITest/preconfig/runCases-chan-install-TLS.txt
sleep 20s

echo "[test_channel.sh] instantiate chaincode"
./pte_driver.sh CITest/preconfig/runCases-chan-instantiate-TLS.txt

cd $CWD
echo "[test_channel.sh] current dir: $PWD"
