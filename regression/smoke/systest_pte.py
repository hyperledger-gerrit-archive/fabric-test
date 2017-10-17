# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

######################################################################
# To execute:
# Install: sudo apt-get install python python-pytest
# Run on command line:
#   cd $GOPATH/src/github.com/hyperledger/fabric-test/regression/smoke
#   py.test -v --junitxml results.xml ./systest_pte.py

import unittest
import subprocess


######################################################################
### COUCHDB
######################################################################

class Perf_Stress_CouchDB(unittest.TestCase):

    @unittest.skip("skipping; WIP")
    def test_FAB3833_2i(self):
        '''
        Description:
        TPS performance measurement test with CouchDB and TLS.
        Launch network, use PTE in Stress Mode to continuously
        send invoke transactions concurrently to 1 peer in both orgs,
        ensure events are raised for each Tx (indicating it was
        written to ledger), calculate tps, remove network and cleanup.
        Artifact Locations: fabric-test/tools/PTE/CITest/FAB-3833-2i
        Logs Location: fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/
        Network Topology: 3 Ord, 4 KB, 3 ZK, 2 Org, 2 Peers/Org, 1 Chan, 1 chaincode (sample_cc), 2 thrds, TLS enabled
        Client Driver: PTE: systest_pte.py, test_pte.sh, test_driver.sh.
        '''
        result = subprocess.check_output("cd ../../tools/PTE/CITest/scripts && ./test_setup.sh && cd ../../../../fabric-sdk-node/test/PTE/CITest/FAB-3833-2i && ./test_nl.sh && cd ../scripts && ./test_driver.sh -e -p FAB3833-2i", shell=True)
        # Hmmm. That is very long and complicated! Maybe we should create
        # another script containing all the necessary commands for the
        # CI to run the test, and put it into the test's own directory
        # ../../tools/PTE/CITest/FAB-3833-2i/.
        # Then we could replace the previous line with simply
        # result = subprocess.check_output("cd ../../tools/PTE/CITest/FAB-3833-2i && ./runCITest.sh", shell=True)

        # Make sure no errors or timeouts occurred for any of the PTE test driver processes
        self.assertNotIn("pte-exec:completed:error", result)
        self.assertNotIn("pte-exec:completed:timeout", result)
        # Check for completion of all of the PTE processes.
        self.assertIn("info: [PTE 0 main]: [performance_main] pte-main:completed", result)
        # Another pte_driver.sh is executed for each line of sdk=node in runCases.txt.
        # Testwriter (you) should check that file in the test folder and add
        # more lines here (incrementing the PTE counter) to ensure they all finish.
        # self.assertIn("info: [PTE 1 main]: [performance_main] pte-main:completed", result)
        # self.assertIn("info: [PTE 2 main]: [performance_main] pte-main:completed", result)
        # self.assertIn("info: [PTE 3 main]: [performance_main] pte-main:completed", result)


######################################################################
### LEVELDB
######################################################################

class Perf_Stress_LevelDB(unittest.TestCase):

    @unittest.skip("skipping")
    def test_FAB3808_2i(self):
        '''
        Description:
        TPS performance measurement test with LevelDB and TLS.
        Launch network, use PTE in Stress Mode to continuously
        send invoke transactions concurrently to 1 peer in both orgs,
        ensure events are raised for each Tx (indicating it was
        written to ledger), calculate tps, remove network and cleanup.
        Artifact Locations: fabric-test/tools/PTE/CITest/FAB-3808-2i
        Logs Location: fabric-test/fabric-sdk-node/test/PTE/CITest/Logs/
        Network Topology: 3 Ord, 4 KB, 3 ZK, 2 Org, 2 Peers/Org, 1 Chan, 1 chaincode (sample_cc), 2 thrds, TLS enabled
        Client Driver: PTE: systest_pte.py, test_pte.sh, test_driver.sh.
        '''
        result = subprocess.check_output("cd ../../tools/PTE/CITest/scripts && ./test_setup.sh && cd ../../../../fabric-sdk-node/test/PTE/CITest/FAB-3808-2i && ./test_nl.sh && cd ../scripts && ./test_driver.sh -e -p FAB3808-2i", shell=True)
        # result = subprocess.check_output("cd ../../tools/PTE/CITest/FAB-3808-2i && ./runCITest.sh", shell=True)

        # Make sure no errors or timeouts occurred for any of the PTE test driver processes
        self.assertNotIn("pte-exec:completed:error", result)
        self.assertNotIn("pte-exec:completed:timeout", result)
        # Check for completion of all of the PTE processes.
        self.assertIn("info: [PTE 0 main]: [performance_main] pte-main:completed", result)
        # Another pte_driver.sh is executed for each line of sdk=node in runCases.txt.
        # Testwriter (you) should check that file in the test folder and add
        # more lines here (incrementing the PTE counter) to ensure they all finish.
        # self.assertIn("info: [PTE 1 main]: [performance_main] pte-main:completed", result)
        # self.assertIn("info: [PTE 2 main]: [performance_main] pte-main:completed", result)
        # self.assertIn("info: [PTE 3 main]: [performance_main] pte-main:completed", result)

