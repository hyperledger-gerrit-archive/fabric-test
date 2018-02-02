#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

########## CI test ##########

CWD=$PWD
PREFIX="result"   # result log prefix

#### Lauch network and synch-up ledger
cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/PTE/CITest/scripts
./test_driver.sh -n -m FAB-7647-6i -p -c samplecc -t FAB-7647-6q
#### remove PTE log from synch-up ledger run
rm -f ../Logs/FAB-7647-6q*.log
#### execute testcase FAB-7627-16i: 4 threads invokes, golevelDB
./test_driver.sh -t FAB-7647-6i
#### gather TPS from docker containers
./get_peerStats.sh -r FAB-7647-6i -p peer0.org1.example.com peer0.org2.example.com -c testorgschannel1 testorgschannel2 testorgschannel3 testorgschannel4 testorgschannel5 testorgschannel6 testorgschannel7 testorgschannel8 -n $PREFIX -o $CWD -v

#### execute testcase FAB-7627-16q: 16 threads queries, golevelDB
./test_driver.sh -t FAB-7647-6q
#### gather TPS from PTE log
grep Summary ../Logs/FAB-7647-6q*.log | grep "QUERY" >> $CWD/$PREFIX"_"FAB-7647-6i".log"
