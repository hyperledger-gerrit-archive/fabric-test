#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

SMOKEDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/smoke"
cd $SMOKEDIR

echo "========== System Test using PTE and NL tools..."
cp -r ../../tools/PTE $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/
cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node
./../pre_setup.sh && npm config set prefix ~/npm && npm install && npm install -g gulp
### TEMPORARY:
### There are no smoke tests yet in PTE.
### Run the pte tests that I modifed in the daily suite, just to use the Verify job to prove it works in the CI:
### gulp ca && cd $SMOKEDIR && py.test -v --junitxml results_systest_pte.xml systest_pte.py
gulp ca && cd $SMOKEDIR/../daily && py.test -v --junitxml results_systest_pte.xml systest_pte.py
cd $SMOKEDIR

echo "========== Behave feature and system tests..."
cd ../../feature
behave --junit --junit-directory ../regression/smoke/. --tags=-skip --tags=smoke -k -D logs=y
cd -

echo "========== Orderer component test using OTE and NL tools..."
py.test -v --junitxml results_orderer_ote.xml orderer_ote.py

