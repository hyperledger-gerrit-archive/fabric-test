#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

########## CI test ##########

CWD=$PWD
TESTCASE='FAB-3833-2i'
pteReport='../../pteReport.txt'
CIpteReport='../Logs/'$TESTCASE'-pteReport.txt'

cd ../scripts

# remove existing pteReport
if [ -e $pteReport ]; then
    echo "remove $pteReport"
    rm -f $pteReport
fi


#### Launch network and synch-up ledger
./test_driver.sh -n -m $TESTCASE -p -c samplecc -t FAB-3810-2q
#### remove PTE log from synch-up ledger run
rm -f ../Logs/FAB-3810-2q*.log
# remove pteReport from priming query
if [ -e $pteReport ]; then
    echo "remove $pteReport"
    rm -f $pteReport
fi


#### execute testcase FAB-3833-2i: 2 threads invokes, couchDB
./test_driver.sh -t $TESTCASE
#### calculate overall invoke TPS from pteReport
node get_pteReport.js $pteReport
mv $pteReport $CIpteReport


#### execute testcase FAB-3810-2q: 2 threads queries, couchDB
./test_driver.sh -t FAB-3810-2q
#### calculate overall query TPS from pteReport
node get_pteReport.js $pteReport
cat $pteReport >> $CIpteReport
grep Summary ../Logs/FAB-3810-2q*.log | grep "QUERY" >> $CIpteReport

echo "$TESTCASE test completed."
