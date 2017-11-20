# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import subprocess
import os

tool_directory = '../../tools/OTE'
logs_directory = './ote_logs'
TEST_PASS_STRING = "RESULT=PASSED"

if not os.path.exists(logs_directory):
    os.makedirs(logs_directory)

class perf_orderer(unittest.TestCase):

    def test_FAB_6996_solo_1ch(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering service, and verify
         delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-6996.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-6996 2>&1",
                                            shell=True,
                                            #stderr=subprocess.STDOUT,  #Uncomment this two lines to see the stdout
                                            #stdout=subprocess.STDOUT,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7024_solo_1ch_500batchsize(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering servicewith batchsize 500,
         and verify delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7024.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7024 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7026_solo_3ch(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering service in 3 channels,
         and verify delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7026.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7026 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7027_solo_3ch_500batchsize(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering service in 3 channels,
         and verify delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7027.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7027 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7036_3ord_kafka_1ch(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering service, and verify
         delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7036.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7036 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7037_3ord_kafka_1ch_500batchsize(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering servicewith batchsize 500,
         and verify delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7037.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7037 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7038_3ord_kafka_3ch(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering service, and verify
         delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7038.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7038 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7039_3ord_kafka_3ch_500batchsize(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering servicewith batchsize 500,
         and verify delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7039.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7039 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7058_12ord_kafka_1ch(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering service, and verify
         delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7058.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7058 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7059_12ord_kafka_1ch_500batchsize(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering servicewith batchsize 500,
         and verify delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7059.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7059 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7060_12ord_kafka_3ch(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering service, and verify
         delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7060.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7060 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)

    def test_FAB_7061_12ord_kafka_3ch_500batchsize(self):
        '''
         Using one broadcast client thread per channel per orderer,
         send 30000 transactions through the ordering servicewith batchsize 500,
         and verify delivery using an equal number of deliver clients.
         Refer to the logs to also see the TPS throughput rate.
        '''
        with open(os.path.join(logs_directory, "ote_FAB-7061.log"), "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-7061 2>&1",
                                            shell=True,
                                            cwd=tool_directory)
            print(result)
            logfile.write(result)
            self.assertIn(TEST_PASS_STRING, result)
