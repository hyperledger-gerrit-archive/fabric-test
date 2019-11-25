#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

CurrentDirectory=$(cd `dirname $0` && pwd)
FabricTestDir="$(echo $CurrentDirectory | awk -F'/fabric-test/' '{print $1}')/fabric-test"
SMOKEDIR="$FabricTestDir/regression/smoke"
cd $SMOKEDIR

# echo "======== Ledger component performance tests using LTE ========"
# py.test -v --junitxml results_ledger_lte_smoke.xml ledger_lte_smoke.py

archivePTE() {
if [ ! -z $GERRIT_BRANCH ] && [ ! -z $WORKSPACE ]; then
# GERRIT_BRANCH is a Jenkins parameter and WORKSPACE is a Jenkins directory.This function is used only when the test is run in Jenkins to archive the log files.
    echo "------> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p $WORKSPACE/archives/PTE_Test_Logs
    cp $FabricTestDir/tools/PTE/CITest/Logs/*.log $WORKSPACE/archives/PTE_Test_Logs/
    mkdir -p $WORKSPACE/archives/PTE_Test_XML
    cp $FabricTestDir/regression/smoke/*.xml $WORKSPACE/archives/PTE_Test_XML/
    cp $FabricTestDir/regression/daily/*.xml $WORKSPACE/archives/PTE_Test_XML/
fi
}

echo "======== Performance Test using PTE and NL tools ========"
cd $FabricTestDir/tools/PTE
if [ ! -d "node_modules" ];then
  npm config set prefix ~/npm
  npm install
  if [ $? != 0 ]; then
    echo "FAILED: Failed to install npm. Cannot run pte test suite."
    # Don't exit.. Continue with tests, to show the PTE failure results
  else
    echo "Successfully installed npm."
  fi
fi
# cd $SMOKEDIR && py.test -v --junitxml results_systest_pte.xml systest_pte.py

echo "======== Smoke Test Suite using ginkgo and operator tools ========"
cd $SMOKEDIR && ginkgo -v
cd $SMOKEDIR/../daily && ginkgo --focus test_FAB7929_8i
echo "------> Smoke tests completed"
archivePTE

