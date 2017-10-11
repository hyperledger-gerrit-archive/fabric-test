#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric/test/regression/daily"

echo "========== Behave feature and system tests..."
python --version
cd ../../feature
behave --junit --junit-directory . -t smoke
python --version
cd -
