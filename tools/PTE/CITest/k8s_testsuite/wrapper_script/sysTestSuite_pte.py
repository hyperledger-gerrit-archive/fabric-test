# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

######################################################################
# To execute:
# Install: sudo apt-get install python python-pytest
# Run on command line: py.test -v --junitxml results_systest_pte.xml ./systest_pte.py

import unittest
import subprocess

logs_directory = '../../../tools/PTE/CITest/Logs'
scenarios_directory = '../../../tools/PTE/CITest/scenarios'
nl_directory = '../../../tools/NL'

# error messages
testScriptFailed =      "Test Failed with non-zero exit code; check for errors in fabric-test/tools/PTE/CITest/Logs/"
noTxSummary =           "Error: pteReport.log does not contain INVOKE Overall transactions"
invokeFailure =         "Error: incorrect number of INVOKE transactions sent or received"
invokeSendFailure =     "Error sending INVOKE proposal to peer or sending broadcast transaction to orderer"
eventReceiveFailure =   "Error: event receive failure: INVOKE TX events arrived late after eventOpt.timeout, and/or transaction events were never received"
invokeCheckError =      "Error during invokeCheck: query result error when validating transaction"
queryCountFailure =     "Error: incorrect number of QUERY transactions sent or received"


    def test_FAB-3833-2i(self):
        '''
        Description:

        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./commonUtil.sh -FAB-3833-2i", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        #returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-3833-2i-pteReport.log", logfilelist)

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" 3833-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 20000 received 20000\" FAB-3833-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall failures: proposal 0 transactions 0\" FAB-3833-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeSendFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall event: received 20000 timeout 0 unreceived 0\" FAB-3833-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=eventReceiveFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 20000 received 20000 failures 0\" FAB-3833-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)
