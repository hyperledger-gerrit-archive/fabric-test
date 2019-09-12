# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import subprocess

logs_directory = '../../tools/PTE/logs'
operator_directory = '../../tools/operator'
k8s_testsuite = '../../tools/PTE/CITest/k8s_testsuite/scripts'

# error messages
testScriptFailed =      "Test Failed with non-zero exit code; check for errors in fabric-test/tools/PTE/CITest"
invokeFailure =         "Error: incorrect number of INVOKE transactions sent or received"
queryCountFailure =     "Error: incorrect number of QUERY transactions sent or received"


class System_Tests_Kafka_Couchdb_TLS(unittest.TestCase):


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
        returncode = subprocess.call("./operator.sh -t samplecc_go_2chan", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 8000 received 8000\" samplecc_go_2chan_i_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 8000 received 8000 failures 0\" samplecc_go_2chan_q_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)

    def test_6samplejs_orgAnchor_2chan(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t samplejs_node_2chan", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 8000 received 8000\" samplejs_node_2chan_i_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 8000 received 8000 failures 0\" samplejs_node_2chan_q_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)


    def test_7sbe_go_2chan_endorse(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t sbe_go_2chan_endorse", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 8000 received 8000\" sbe_go_2chan_endorse_2chan_i_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

    def test_8samplecc_go_10K_payload(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t samplecc_go_10K_payload", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 400 received 400\" samplecc_go_10K_i_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

    def test_9samplecc_go_4M_payload(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t samplecc_go_4M_payload", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 400 received 400\" samplecc_go_4M_i_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

    def test_10samplecc_go_49M_payload(self):
        '''
        Description:

        '''

        # Run the test scenario: Execute invokes and query tests.
        returncode = subprocess.call("./operator.sh -t samplecc_go_49M_payload", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 1 received 1\" samplecc_go_49M_i_pteReport.txt | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

    def test_11tearDownNetwork(self):
        '''
        Description:

        '''

        # Teardown the network
        returncode = subprocess.call("./operator.sh -a down -f ../networkSpecFiles/kafka_couchdb_tls.yaml", cwd=k8s_testsuite, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
