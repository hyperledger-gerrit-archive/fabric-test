#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"

echo "1.========= Installing gulp ============"
npm install -g gulp
echo "2.========= Updating Submodules ======="
git submodule foreach git pull origin master

cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node
npm install && gulp ca
echo "<=============PTE============>"
cd $GOPATH/src/github.com/hyperledger/fabric-test/tools
cp -r PTE $GOPATH/src/github.com/hyperledger/fabric-test/fabric-sdk-node/test
cd $DAILYDIR
echo "====================================================================="
#echo "========== Sample Tests..."
#py.test -v --junitxml results_sample.xml Example.py

echo "========== System Test Performance Stress tests driven by PTE tool..."
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

echo "========== Fabric-CA Clustering test..."
py.test -v --junitxml results_cluster.xml ca_cluster.py

echo "========== Orderer Performance tests..."
py.test -v --junitxml results_orderer_ote.xml orderer_ote.py
