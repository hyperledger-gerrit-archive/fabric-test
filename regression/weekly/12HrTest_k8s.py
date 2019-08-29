# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import subprocess

logs_directory = '../../tools/PTE/CITest/scripts'
operator_directory = '../../tools/operator'
k8s_testsuite = '../../tools/PTE/CITest/k8s_testsuite/scripts'

# error messages
testScriptFailed =      "Test Failed with non-zero exit code; check for errors in fabric-test/tools/PTE/CITest"
invokeFailure =         "Error: incorrect number of INVOKE transactions sent or received"

class System_Tests_Kafka_Couchdb_TLS_12hr(unittest.TestCase):


    def test_1downNetwork(self):
        '''
        Description:

        '''

        # Teardown the network
        returncode = subprocess.call("./operator.sh -a down -f ../networkSpecFiles/kafka_couchdb_tls.yaml", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)


    def test_2launchNetwork(self):
        '''
        Description:

        '''

        # Launch the network
        returncode = subprocess.call("./operator.sh -a up -f ../networkSpecFiles/kafka_couchdb_tls.yaml", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

    def test_3createJoinChannel(self):
        '''
        Description:

        '''

        returncode = subprocess.call("./operator.sh -c", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

    def test_4installInstantiation(self):
        '''
        Description:

        '''

        returncode = subprocess.call("./operator.sh -i", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

    def test_5samplecc_orgAnchor_2chan(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t samplecc_go_12hr", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall failures: proposal 0 transactions 0\" FAB-3833-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeSendFailure)

    def test_6tearDownNetwork(self):
        '''
        Description:

        '''

        # Teardown the network
        returncode = subprocess.call("./operator.sh -a down -f ../networkSpecFiles/kafka_couchdb_tls.yaml", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
