#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

SMOKEDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/smoke"
cd $SMOKEDIR

echo "======== Behave feature and system tests ========"
cd ../../feature
    echo "======== These are all the DAILY tagged behave tests (with results in regression/smoke/) ========"
    behave --junit --junit-directory ../regression/smoke/. --tags=-skip --tags=daily -k -D logs=y && echo "======== Behave feature tests completed; skipping other tests. ========"
    exit
behave --junit --junit-directory ../regression/smoke/. --tags=-skip --tags=smoke -k -D logs=y
cd -



echo "======== Ledger component performance tests using LTE ========"
py.test -v --junitxml results_ledger_lte_smoke.xml ledger_lte_smoke.py

echo "======== Orderer component test using OTE and NL tools ========"
py.test -v --junitxml results_orderer_ote.xml orderer_ote.py

echo "======== Performance Test using PTE and NL tools ========"
cd $GOPATH/src/github.com/hyperledger/fabric-test/tools/PTE
npm config set prefix ~/npm
npm install
if [ $? != 0 ]; then
    echo "FAILED: Failed to install npm. Cannot run pte test suite."
    # Don't exit.. Continue with tests, to show the PTE failure results
else
    echo "Successfully installed npm."
fi
cd $SMOKEDIR && py.test -v --junitxml results_systest_pte.xml systest_pte.py
