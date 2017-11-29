#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

SMOKEDIR="$GOPATH/src/github.com/hyperledger/fabric-test/regression/smoke"

echo "========== Behave feature and system tests..."
cd ../../feature
behave --junit --junit-directory ../regression/smoke/. --tags=testFAB6333 -k -D logs=y
cd -

