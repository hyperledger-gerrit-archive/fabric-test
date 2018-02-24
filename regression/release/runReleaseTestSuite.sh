#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

DAILY_DIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/daily"
RELEASE_DIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/release"
FABRIC_ROOT_DIR=$GOPATH/src/github.com/hyperledger/fabric-test

cd $RELEASE_DIR

docker rm -f $(docker ps -aq) || true
echo "=======> Execute BYFN tests..."
py.test -v --junitxml results_byfn_cli.xml byfn_release_tests.py

docker rm -f $(docker ps -aq) || true
echo "=======> Execute SDK tests... (JAVA & NODE)"
py.test -v --junitxml results_e2e_sdk.xml e2e_sdk_release_tests.py

docker rm -f $(docker ps -aq) || true
echo "=======> Execute make targets"
py.test -v --junitxml results_make_targets.xml make_targets_release_tests.py
