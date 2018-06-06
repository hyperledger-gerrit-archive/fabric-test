#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"
cd $DAILYDIR

echo "========== System Test Performance tests using PTE and NL tools..."
cd $GOPATH/src/github.com/hyperledger/fabric-test/tools/PTE

npm install && npm install gulp
if [ $? != 0 ]; then
   echo "------> Could not install npm, exiting test.." && exit 1
else
   echo "------> npm is installed"
fi

cd $DAILYDIR && py.test -v --junitxml results_systest_pte.xml systest_pte.py
