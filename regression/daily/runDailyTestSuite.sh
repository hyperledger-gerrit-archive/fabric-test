#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"

#echo "========== Sample Tests..."
#py.test -v --junitxml results_sample.xml Example.py

### comment out pte performance systests temporarily, until
### Jenkins CI can run them successfully without timing out...
echo "========== System Test Performance Stress tests driven by PTE tool..."

# JENKINS
# cp -r ../../tools/PTE $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/

cp -r ../../tools/PTE $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test/

# JENKINS
# cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test/fabric-sdk-node

cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node

./../pre_setup.sh && npm config set prefix ~/npm && npm install && npm install -g gulp
gulp ca || exit 1
ls
cd ../regression/daily
echo "==========PY Test============"
py.test -v --junitxml results_systest_pte.xml systest_pte.py

echo "========== Behave feature and system tests..."
cd ../../feature
behave --junit --junit-directory ../regression/daily/. --tags=-skip --tags=daily -k -D logs=y
cd -

echo "========== Ledger component performance tests..."
py.test -v --junitxml results_ledger_lte.xml ledger_lte.py

# the auction_daily test is disabled until the CI issue is fixed
#echo "========== Test Auction Chaincode ..."
#py.test -v --junitxml results_auction_daily.xml testAuctionChaincode.py

echo "========== Fabric-CA ACL smoke test..."
py.test -v --junitxml results_acl.xml acl_happy_path.py

echo "========== Fabric-CA tests..."
py.test -v --junitxml results_fabric-ca_tests.xml ca_tests.py

#echo "========== Orderer Performance tests..."
#py.test -v --junitxml results_orderer_ote.xml orderer_ote.py
