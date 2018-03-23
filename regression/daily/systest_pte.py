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

######################################################################
### COUCHDB
######################################################################

scenarios_directory = '../../fabric-sdk-node/test/PTE/CITest/scenarios'

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

        Logs Artifacts Locations:
        - Scenario ResultLogs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/scenarios/result_FAB-3833-2i.log
        - PTE Testcase Logs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3833-2i-<MMDDHHMMSS>.log
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3810-2q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario, including both the invokes and query tests.
        # We do these two testcases together in this one test scenario, with
        # one network, because the query test needs to query all those same
        # invokes have to be done first anyways before we can query them.
        returncode = subprocess.call("./FAB-3833-2i.sh",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg="Test Failed; check for errors in fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/")

        # Check the result log file for an output line with "tx Num: <number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread
        # (one for each org). And, since each thread sends 10000 TX, then
        # the tx Num (sum TXs delivered for all threads) is 20000.
        invokeTxSucceeded = subprocess.check_output(
                "grep -c \"tx Num: 20000,\" result_FAB-3833-2i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(invokeTxSucceeded.strip()), 2)

        # Check the result log file for an output line with "QUERY transaction=<number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread;
        # the total query count on each peer is 10000.
        queryTxSucceeded = subprocess.check_output(
                "grep -c \"QUERY transaction=10000,\" result_FAB-3833-2i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(queryTxSucceeded.strip()), 2)

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

        Logs Artifacts Locations:
        - Scenario ResultLogs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/scenarios/result_FAB-3832-4i.log
        - PTE Testcase Logs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3832-4i-<MMDDHHMMSS>.log
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3834-4q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario, including both the invokes and query tests.
        # We do these two testcases together in this one test scenario, with
        # one network, because the query test needs to query all those same
        # invokes have to be done first anyways before we can query them.
        returncode = subprocess.call("./FAB-3832-4i.sh",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg="Test Failed; check for errors in fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/")

        # Check the result log file for an output line with "tx Num: <number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread
        # (one for each org). And, since each thread sends 10000 TX, then
        # the tx Num (sum TXs delivered for all threads) is 40000.
        invokeTxSucceeded = subprocess.check_output(
                "grep -c \"tx Num: 40000,\" result_FAB-3832-4i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(invokeTxSucceeded.strip()), 2)

        # Check the result log file for an output line with "QUERY transaction=<number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread;
        # the total query count on each peer is 20000.
        queryTxSucceeded = subprocess.check_output(
                "grep -c \"QUERY transaction=20000,\" result_FAB-3832-4i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(queryTxSucceeded.strip()), 2)




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

        Logs Artifacts Locations:
        - Scenario ResultLogs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/scenarios/result_FAB-3808-2i.log
        - PTE Testcase Logs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3808-2i-<MMDDHHMMSS>.log
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3811-2q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario, including both the invokes and query tests.
        # We do these two testcases together in this one test scenario, with
        # one network, because the query test needs to query all those same
        # invokes have to be done first anyways before we can query them.
        returncode = subprocess.call("./FAB-3808-2i.sh",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg="Test Failed; check for errors in fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/")

        # Check the result log file for an output line with "tx Num: <number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread
        # (one for each org). And, since each thread sends 10000 TX, then
        # the tx Num (sum TXs delivered for all threads) is 20000.
        invokeTxSucceeded = subprocess.check_output(
                "grep -c \"tx Num: 20000,\" result_FAB-3808-2i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(invokeTxSucceeded.strip()), 2)

        # Check the result log file for an output line with "QUERY transaction=<number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread;
        # the total query count on each peer is 10000.
        queryTxSucceeded = subprocess.check_output(
                "grep -c \"QUERY transaction=10000,\" result_FAB-3808-2i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(queryTxSucceeded.strip()), 2)

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

        Logs Artifacts Locations:
        - Scenario ResultLogs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/scenarios/result_FAB-3807-4i.log
        - PTE Testcase Logs:
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3807-4i-<MMDDHHMMSS>.log
            fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/FAB-3835-4q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario, including both the invokes and query tests.
        # We do these two testcases together in this one test scenario, with
        # one network, because the query test needs to query all those same
        # invokes have to be done first anyways before we can query them.
        returncode = subprocess.call("./FAB-3807-4i.sh",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg="Test Failed; check for errors in fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/")

        # Check the result log file for an output line with "tx Num: <number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread
        # (one for each org). And, since each thread sends 10000 TX, then
        # the tx Num (sum TXs delivered for all threads) is 40000.
        invokeTxSucceeded = subprocess.check_output(
                "grep -c \"tx Num: 40000,\" result_FAB-3807-4i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(invokeTxSucceeded.strip()), 2)

        # Check the result log file for an output line with "QUERY transaction=<number>".
        # If the invokes testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each thread;
        # the total query count on each peer is 20000.
        queryTxSucceeded = subprocess.check_output(
                "grep -c \"QUERY transaction=20000,\" result_FAB-3807-4i.log",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(queryTxSucceeded.strip()), 2)
