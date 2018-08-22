#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"
cd $DAILYDIR

archiveCA() {  
    echo "-----> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p $WORKSPACE/archives/CA_Test_Logs
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/fabric-samples/fabric-ca/data/logs/*.log $WORKSPACE/archives/CA_Test_Logs/
    mkdir -p $WORKSPACE/archives/CA_Test_XML
    cp -r $GOPATH/src/github.com/hyperledger/fabric-test/regression/daily/*.xml $WORKSPACE/archives/CA_Test_XML/
}

echo "======== Fabric-CA ACL smoke test... ========"
py.test -v --junitxml results_acl.xml acl_happy_path.py && echo "------> Fabric-CA ACL smoke-test completed."

echo "======== Fabric-CA tests...========"
py.test -v --junitxml results_fabric-ca_tests.xml ca_tests.py && echo "------> Fabric-CA tests completed."
archiveCA
