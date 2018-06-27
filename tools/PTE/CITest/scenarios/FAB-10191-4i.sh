#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

########## CI test ##########

CWD=$PWD

#### Launch network and synch-up ledger
cd ../scripts
./test_driver.sh -n -m FAB-10191-4i -p -c samplejs -t FAB-10190-4q
#### remove PTE log from synch-up ledger run
rm -f ../Logs/FAB-10190-4q*.log
#### execute testcase FAB-10191-4i: 4 threads invokes, golevelDB
./test_driver.sh -t FAB-10191-4i &
#### wait for the transactions to start
sleep 180

#### restart devices one at a time
./test_chaos.sh -o 3 -g 2 -p 2 -k 4 -z 3

#### wait for the transactions to back to normal
sleep 180

#### exection completed, stop transactions
echo "[$0] execution completed"
echo "[$0] stop transaction"
kill -9 $(ps -a | grep node | awk '{print $1}')

cd $CWD
