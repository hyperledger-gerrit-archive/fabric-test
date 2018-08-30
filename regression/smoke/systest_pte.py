# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import subprocess

TEST_PASS_STRING="RESULT=PASS"

scenarios_directory = '../../tools/PTE/CITest/scenarios'
nl_directory = '../../tools/NL'


class PTE_Basic_Function(unittest.TestCase):

#   @unittest.skip("skipping; WIP")
    # Use FAB-8099 add 7929 to this automated smoke test suite
    def test_FAB7929_8i(self):
   #def test_FAB3833_2i_FAB3810_2q(self):
        '''
        Description:

        Functional and TPS performance measurement test.
        - This scenario launches a network, as defined below,
          and runs two tests - for invokes, and for queries -
          on single host using networkLauncher (after removing
          any existing network and artifacts).

        Network Topology: 3 Ord, 4 KB, 3 ZK, 2 Org, 2 Peers/Org, TLS enabled
          4 Channels, 1 chaincode (sample_cc), 8 threads total

        Part 1:
        - Use PTE in Constant Mode to continuously send INVOKE
          transactions concurrently to 1 peer in both orgs,
          for each of the 4 channels (8 threads total, each
          send 100 transaction proposals)
        - Register a listener to receive an event for each
          Block (not per transaction) per
          Channel (full block events - not filtered blocks)
          and ensure events are raised for each Tx (indicating
          each was written to ledger successfully)
        - Count TXs and calculate TPS results

        Part 2:
        - QUERY all the invoked transactions
        - Count successes and calculate TPS results

        Logs Artifacts Locations:
        - Scenario ResultLogs:
            fabric-test/tools/PTE/CITest/scenarios/result_FAB-7929-8i.log
        - PTE Testcase Logs:
            fabric-test/tools/PTE/CITest/Logs/FAB-7929-8i-<MMDDHHMMSS>.log
            fabric-test/tools/PTE/CITest/Logs/FAB-7929-8q-<MMDDHHMMSS>.log
        '''

        # Run the test scenario: launch network and run the invokes and query tests.
        # We do these two testcases together in this one test scenario, with
        # one network, because the query test needs to query all those same
        # transactions that were done with the invokes.
        returncode = subprocess.call("./FAB-7929-8i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg="Test Failed; check for errors in fabric-test/tools/PTE/CITest/Logs/")
        # tear down the network, including all the nodes docker containers
        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)

        # Check the result log file for one line of output from every peer
        # that is used for traffic, since those are the peers (typically
        # one per org) from which we will collect stats of the number of
        # TX written to the ledger. The summary line should contain
        #     "Channel: all, tx Num: <number>,"
        # This testcase uses 4 channels, one thread per channel, on one peer
        # of each org (total 8 threads). Since all peers are joined to all
        # channels, then all the TX in all threads will be received and written
        # to the ledgers on all peers. Since each thread sends 100,
        # then the total tx Num for all channels on each peer is 4x200=800.
        # For most typical tests, compute the per-peer invoke tx number as
        # (#orgs * #chaincodes * #channels * #threads per org * 10,000 TX per thread):
        #     2*1*4*1*100=800
        # and the expected count of occurances will be the number of orgs:
        #     2
        invokeTxSucceeded = subprocess.check_output(
                "grep \"Channel: all, tx Num: 800,\" result_FAB-7929-8i.log | wc -l",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(invokeTxSucceeded.strip()), 2)

        # Check the result log file for an output line containing
        # "Total QUERY transaction <number>,"
        # This is seen on the same line as "Aggregate Test Summary".
        # If the query testcase ran to completion and the results were
        # tabulated ok, then we should see one line printed for each
        # chaincode and channel (multiplied by number of threads of each),
        # appended onto the same result_*.log file as the invokes test used.
        # We use an equal number of threads for queries as were used for
        # the accompanying invokes test, above. In this testcase, the total
        # number of threads is 8, each sending 10000 queries.
        # Compute the per-chaincode per-channel query tx number on one peer as
        # (#chaincodes * #channels * #threads per org * 100 TX per thread):
        #     1*4*1*100=400
        # and compute the count of occurances as (#orgs * #threads per org * #channels):
        #     2*1*4=8
        queryTxSucceeded = subprocess.check_output(
                "grep \"Total QUERY transaction 400,\" result_FAB-7929-8i.log | wc -l",
                cwd=scenarios_directory, shell=True)
        self.assertEqual(int(queryTxSucceeded.strip()), 8)

