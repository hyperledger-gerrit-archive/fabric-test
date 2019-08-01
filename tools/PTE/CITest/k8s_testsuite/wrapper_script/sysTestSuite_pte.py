# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import subprocess

logs_directory = '../../../../../tools/PTE/CITest/scripts'
operator_directory = '../../../../../tools/operator'
k8s_testsuite = '../../../../../tools/PTE/CITest/k8s_testsuite/scripts'

# error messages
testScriptFailed =      "Test Failed with non-zero exit code; check for errors in fabric-test/tools/PTE/CITest/Logs/"
invokeFailure =         "Error: incorrect number of INVOKE transactions sent or received"
queryCountFailure =     "Error: incorrect number of QUERY transactions sent or received"


class System_Tests_Kafka_Couchdb_TLS(unittest.TestCase):


    def test_1networkDown(self):
        '''
        Description:

        '''

        # Teardown the network
        returncode = subprocess.call("./operator.sh -a down", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

    def test_2networkLaunch(self):
        '''
        Description:

        '''

        # Launch the network
        returncode = subprocess.call("./operator.sh -a up", cwd=k8s_testsuite, shell=True)
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

    def test_5samplecc_OrgAnchor_2Chan(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t FAB-3833-2i", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 40 received 40\" FAB-3833-2i-pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 40 received 40 failures 0\" FAB-3833-2q-pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)


    def test_6samplejs_OrgAnchor_2Chan(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t FAB-4038-2i", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 40 received 40\" FAB-4038-2i-pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 40 received 40 failures 0\" FAB-4038-2q-pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)

    def test_7tearDownNetwork(self):
        '''
        Description:

        '''

        # Teardown the network
        returncode = subprocess.call("./operator.sh -a down", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
