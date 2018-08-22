#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"
cd $DAILYDIR

archiveOTE() {  
    echo "-----> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p $WORKSPACE/archives/OTE_Test_Logs
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/regression/daily/ote_logs/*.log $WORKSPACE/archives/OTE_Test_Logs/
    mkdir -p $WORKSPACE/archives/OTE_Test_XML
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/regression/daily/*.xml $WORKSPACE/archives/OTE_Test_XML/
} 
echo "======== Orderer Performance tests...========"
py.test -v --junitxml results_orderer_ote.xml orderer_ote.py && echo "-----> OTE Tests completed"
archiveOTE
