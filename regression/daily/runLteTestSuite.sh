#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"
cd $DAILYDIR

archiveLTE() {
if [ ! -z "$(echo $GERRIT_BRANCH)" ]; then
# WORKSPACE is a Jenkins parameter.This condition is used only when the test is run in Jenkins to archive the log files.
    echo "------> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p $WORKSPACE/archives/LTE_Test_Logs
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/regression/daily/*.log $WORKSPACE/archives/LTE_Test_Logs/
    mkdir -p $WORKSPACE/archives/LTE_Test_XML
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/regression/daily/*.xml $WORKSPACE/archives/LTE_Test_XML/
fi
}

echo "======== Ledger component performance tests...========"
py.test -v --junitxml results_ledger_lte.xml ledger_lte.py && echo "------> LTE Tests completed."
archiveLTE
