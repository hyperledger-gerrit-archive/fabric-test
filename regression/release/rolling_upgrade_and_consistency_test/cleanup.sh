#!/bin/bash
TEST_TYPE=$1

rm -rf org1_peer0/ledgerData org1_peer0/msp org1_peer0/tls 2> /dev/null
rm -rf org2_peer0/ledgerData org2_peer0/msp org2_peer0/tls 2> /dev/null

rm -rf orderer/ledgerData orderer/msp orderer/tls 2> /dev/null
rm ch1.block *.pb *.json 2> /dev/null
rm config/genesis.block 2> /dev/null
rm config/ch1.tx 2> /dev/null
rm config/Org1MSPanchors.tx config/Org2MSPanchors.tx 2> /dev/null
rm -rf config/crypto-config 2> /dev/null

rm *.txt

docker ps --all | grep marbles_private | awk '{print $1}' | xargs docker rm -f 2> /dev/null
docker images | grep marbles_private | awk '{print $3}' | xargs docker rmi 2> /dev/null

if [ $TEST_TYPE = "add_a_new_peer" ]; then
	rm -rf org2_peer1/ledgerData org2_peer1/msp org2_peer1/tls 2> /dev/null
	docker ps --all | grep marbles | awk '{print $1}' | xargs docker rm -f 2> /dev/null
	docker images | grep marbles | awk '{print $3}' | xargs docker rmi 2> /dev/null
fi

