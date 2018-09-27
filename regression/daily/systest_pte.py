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

TEST_PASS_STRING="RESULT=PASS"

logs_directory = '../../tools/PTE/CITest/Logs'
scenarios_directory = '../../tools/PTE/CITest/scenarios'
nl_directory = '../../tools/NL'

testScriptFailed =      "Test Failed with non-zero exit code; check for errors in fabric-test/tools/PTE/CITest/Logs/"
noTxSummary =           "Error: pteReport.log does not contain INVOKE Overall transactions"
invokeFailure =         "Error: incorrect number of INVOKE transactions sent or received"
invokeSendFailure =     "Error sending INVOKE proposal to peer or sending broadcast transaction to orderer"
eventReceiveFailure =   "Error: event receive failure: INVOKE TX events arrived late after eventOpt.timeout, and/or transaction events were never received"
queryCountFailure =     "Error: incorrect number of QUERY transactions sent or received"


######################################################################
### COUCHDB
######################################################################

class Perf_Stress_CouchDB(unittest.TestCase):

    def test_FAB3833_2i_FAB3810_2q(self):
        '''
        Description:

        TPS performance measurement test with CouchDB and TLS.
        - This scenario launches a network, as defined below,
          and runs two tests - for invokes, and for queries -
          on single host using networkLauncher (after removing
          any existing network and artifacts).

        Network Topology: 3 Ord, 4 KB, 3 ZK, 2 Org, 2 Peers/Org,
          1 Channel, 1 chaincode (sample_cc), 2 threads, TLS enabled

        Part 1: FAB-3833
        - Use PTE in Stress Mode to continuously send INVOKE
          transactions concurrently to 1 peer in both orgs,
        - Ensure events are raised for each Tx (indicating
          each was written to ledger)

        Part 2: FAB-3810
        - Same as Part 1 - but use QUERY instead of INVOKE

        Part 3: Count TXs and calculate results for both testcases in this scenario

        Logs Artifacts Locations, PTE Testcase Logs:
            fabric-test/tools/PTE/CITest/Logs/FAB-3833-2i-pteReport.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3833-2i-<MMDDHHMMSS>.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3810-2q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-3833-2i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-3833-2i-pteReport.log", logfilelist)

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-3833-2i-pteReport.log | wc -l",
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
                "grep \"CONSTANT QUERY Overall transactions: sent 20000 received 20000\" FAB-3833-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)


    def test_FAB3832_4i_FAB3834_4q(self):
        '''
        Description:

        TPS performance measurement test with CouchDB and TLS.
        - This scenario launches a network, as defined below,
          and runs two tests - for invokes, and for queries -
          on single host using networkLauncher (after removing
          any existing network and artifacts).

        Network Topology: 3 Ord, 4 KB, 3 ZK, 2 Org, 2 Peers/Org,
          1 Channel, 1 chaincode (sample_cc), 4 threads, TLS enabled

        Part 1: FAB-3832
        - Use PTE in Stress Mode to continuously send INVOKE
          transactions concurrently to 1 peer in both orgs,
        - Ensure events are raised for each Tx (indicating
          each was written to ledger)

        Part 2: FAB-3834
        - Same as Part 1 - but use QUERY instead of INVOKE

        Part 3: Count TXs and calculate results for both testcases in this scenario

        Logs Artifacts Locations, PTE Testcase Logs:
            fabric-test/tools/PTE/CITest/Logs/FAB-3832-4i-pteReport.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3832-4i-<MMDDHHMMSS>.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3834-4q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-3832-4i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-3832-4i-pteReport.log", logfilelist)

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-3832-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 40000 received 40000\" FAB-3832-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall failures: proposal 0 transactions 0\" FAB-3832-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeSendFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall event: received 40000 timeout 0 unreceived 0\" FAB-3832-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=eventReceiveFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 40000 received 40000\" FAB-3832-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)


    def test_FAB8192_4i_marbles_FAB8199_4q_FAB8200_4q_FAB8201_4q(self):
        '''
        FAB-8192-4i marbles02 couchdb 4 threads x 1000 invokes (initMarble),
            and 4 x 1000 (three types of queries):
            FAB-8199-4q: 4 threads queries: readMarble
            FAB-8200-4q: 4 threads rich queries: queryMarblesByOwner
            FAB-8201-4q: 4 threads rich queries: queryMarbles
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-8192-4i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-8192-4i-pteReport.log", logfilelist)
        ### should we also check if other report files were created for the queries tests, or are they all included in the one?

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-8192-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        # count = subprocess.check_output(
        #


######################################################################
### LEVELDB
######################################################################

class Perf_Stress_LevelDB(unittest.TestCase):

    def test_FAB3808_2i_FAB3811_2q(self):
        '''
        Description:

        TPS performance measurement test with levelDB and TLS.
        - This scenario launches a network, as defined below,
          and runs two tests - for invokes, and for queries -
          on single host using networkLauncher (after removing
          any existing network and artifacts).

        Network Topology: 3 Ord, 4 KB, 3 ZK, 2 Org, 2 Peers/Org,
          1 Channel, 1 chaincode (sample_cc), 2 threads, TLS enabled

        Part 1: FAB-3808
        - Use PTE in Stress Mode to continuously send INVOKE
          transactions concurrently to 1 peer in both orgs,
        - Ensure events are raised for each Tx (indicating
          each was written to ledger)

        Part 2: FAB-3811
        - Same as Part 1 - but use QUERY instead of INVOKE

        Part 3: Count TXs and calculate results for both testcases in this scenario

        Logs Artifacts Locations, PTE Testcase Logs:
            fabric-test/tools/PTE/CITest/Logs/FAB-3808-2i-pteReport.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3808-2i-<MMDDHHMMSS>.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3811-2q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-3808-2i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-3808-2i-pteReport.log", logfilelist)

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-3808-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 20000 received 20000\" FAB-3808-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall failures: proposal 0 transactions 0\" FAB-3808-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeSendFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall event: received 20000 timeout 0 unreceived 0\" FAB-3808-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=eventReceiveFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 20000 received 20000\" FAB-3808-2i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)


    def test_FAB3807_4i_FAB3835_4q(self):
        '''
        Description:

        TPS performance measurement test with levelDB and TLS.
        - This scenario launches a network, as defined below,
          and runs two tests - for invokes, and for queries -
          on single host using networkLauncher (after removing
          any existing network and artifacts).

        Network Topology: 3 Ord, 4 KB, 3 ZK, 2 Org, 2 Peers/Org,
          1 Channel, 1 chaincode (sample_cc), 4 threads, TLS enabled

        Part 1: FAB-3807
        - Use PTE in Stress Mode to continuously send INVOKE
          transactions concurrently to 1 peer in both orgs,
        - Ensure events are raised for each Tx (indicating
          each was written to ledger)

        Part 2: FAB-3835
        - Same as Part 1 - but use QUERY instead of INVOKE

        Part 3: Count TXs and calculate results for both testcases in this scenario

        Logs Artifacts Locations, PTE Testcase Logs:
            fabric-test/tools/PTE/CITest/Logs/FAB-3807-4i-pteReport.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3807-4i-<MMDDHHMMSS>.log
            fabric-test/tools/PTE/CITest/Logs/FAB-3835-4q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-3807-4i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-3807-4i-pteReport.log", logfilelist)

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-3807-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall transactions: sent 40000 received 40000\" FAB-3807-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall failures: proposal 0 transactions 0\" FAB-3807-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=invokeSendFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT INVOKE Overall event: received 40000 timeout 0 unreceived 0\" FAB-3807-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=eventReceiveFailure)

        count = subprocess.check_output(
                "grep \"CONSTANT QUERY Overall transactions: sent 40000 received 40000\" FAB-3807-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=queryCountFailure)


    def test_FAB7329_4i_channel_events(self):
        '''
        FAB-7329 channel events, 1 ch NodeJS cc, 4 thrds
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-7329-4i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-7329-4i-pteReport.log", logfilelist)
        ### should we also check if other report files were created for the queries tests, or are they all included in the one?

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-7329-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        # count = subprocess.check_output(
        #


    def test_FAB7333_4i_filtered_block_events(self):
        '''
        FAB-7333 filtered block events, 1 ch NodeJS cc, 4 thrds
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-7333-4i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-7333-4i-pteReport.log", logfilelist)
        ### should we also check if other report files were created for the queries tests, or are they all included in the one?

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-7333-4i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        # count = subprocess.check_output(
        #


    def test_FAB7647_1i_latency(self):
        '''
        FAB-7647-1i.sh latency for single blocking thread, 1 transaction at a time
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        returncode = subprocess.call("./FAB-7647-1i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg=testScriptFailed)
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # check if the test created the report file
        logfilelist = subprocess.check_output("ls", cwd=logs_directory, shell=True)
        self.assertIn("FAB-7647-1i-pteReport.log", logfilelist)
        ### should we also check if other report files were created for the queries tests, or are they all included in the one?

        # check if the test finished and printed the Overall summary
        count = subprocess.check_output(
                "grep \"INVOKE Overall transactions:\" FAB-7647-1i-pteReport.log | wc -l",
                cwd=logs_directory, shell=True)
        self.assertEqual(int(count.strip()), 1, msg=noTxSummary)

        # check the counts
        # count = subprocess.check_output(
        #


