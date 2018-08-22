#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"
cd $DAILYDIR

archiveBehave() {
    echo "-----> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p $WORKSPACE/archives/Behave_Test_Logs
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/feature/*.log $WORKSPACE/archives/Behave_Test_Logs/
    mkdir -p $WORKSPACE/archives/Behave_Test_XML
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/regression/daily/*.xml $WORKSPACE/archives/Behave_Test_XML/
}

echo "======== Behave feature and system tests...========"
cd ../../feature
behave --junit --junit-directory ../regression/daily/. --tags=-skip --tags=daily -k -D logs=y && echo "------> Behave feature tests completed."
archiveBehave
