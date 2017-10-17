#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

SMOKEDIR="$GOPATH/src/github.com/hyperledger/fabric/test/regression/smoke"

echo "========== Behave feature and system tests..."
cd ../../feature
behave --junit --junit-directory ../regression/smoke/. --tags=-skip --tags=smoke
cd -

# The next two lines can be uncommented, after the perf testcases and scripts are merged for FAB-3833...
#echo "========== System Test Performance Stress tests driven by PTE tool..."
#py.test -v --junitxml results_systest_pte.xml systest_pte.py

