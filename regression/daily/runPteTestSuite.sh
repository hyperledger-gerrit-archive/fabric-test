#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"
cd $DAILYDIR

echo "========== System Test Performance tests using PTE and NL tools..."
cp -r ../../tools/PTE $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/
cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node
./../pre_setup.sh && npm config set prefix ~/npm && npm install && npm install -g gulp
gulp ca && cd $DAILYDIR && py.test -v --junitxml results_systest_pte.xml systest_pte.py
