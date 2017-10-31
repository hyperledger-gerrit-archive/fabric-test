#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

FabricTestDir=$GOPATH/src/github.com/hyperledger/fabric-test

CWD=$PWD

sleep 180
# restart orderer0.example.com
echo "[$0] restart orderer0.example.com"
docker restart orderer0.example.com
sleep 90

# restart orderer1.example.com
echo "[$0] restart orderer1.example.com"
docker restart orderer1.example.com
sleep 90

# restart peer0.org1.example.com
echo "[$0] restart peer0.org1.example.com"
docker restart peer0.org1.example.com
sleep 90

# restart peer1.org1.example.com
echo "[$0] restart peer1.org1.example.com"
docker restart peer1.org1.example.com
sleep 90

# restart peer0.org2.example.com
echo "[$0] restart peer0.org2.example.com"
docker restart peer0.org2.example.com
sleep 90

# restart peer1.org2.example.com
echo "[$0] restart peer1.org2.example.com"
docker restart peer1.org2.example.com
sleep 90

# stop kafka0 for 45s
echo "[$0] restart kafka0"
docker stop kafka0
sleep 45
docker start kafka0
sleep 90

# stop kafka1 for 45s
echo "[$0] restart kafka1"
docker stop kafka1
sleep 45
docker start kafka1
sleep 90

# stop kafka2 for 45s
echo "[$0] restart kafka2"
docker stop kafka2
sleep 45
docker start kafka2
sleep 90

# stop kafka3 for 45s
echo "[$0] restart kafka3"
docker stop kafka3
sleep 45
docker start kafka3
sleep 90

# stop zookeeper0 for 45s
echo "[$0] restart zookeeper0"
docker stop zookeeper0
sleep 45
docker start zookeeper0
sleep 90

# stop zookeeper1 for 45s
echo "[$0] restart zookeeper1"
docker stop zookeeper1
sleep 45
docker start zookeeper1
sleep 120

# stop zookeeper2 for 45s
echo "[$0] restart zookeeper2"
docker stop zookeeper2
sleep 45
docker start zookeeper2
sleep 120

cd $CWD
echo "[$0] current dir: $PWD"
