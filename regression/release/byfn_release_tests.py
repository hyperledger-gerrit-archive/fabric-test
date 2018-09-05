#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################
import unittest
import subprocess

class byfn_cli_release_tests(unittest.TestCase):

    def test_byfn_cli_default_channel(self):
        '''
         In this cli test, we execute the byfn_cli tests on published release
         docker images and pull published fabric binaries and perform tests on
         fabric-samples repository.

         Passing criteria: byfn_cli test completed successfully with
         exit code 0
        '''
        logfile = open("output_byfn_cli_default_channel.log", "w")
        returncode = subprocess.call(
                "./run_byfn_cli_release_tests.sh",
                shell=True, stderr=subprocess.STDOUT, stdout=logfile)
        logfile.close()
        self.assertEqual(returncode, 0, msg="test_byfn_cli_default_channel "
                "tests are failed. \nPlease check the logfile "
                +logfile.name+" for more details.")

    # def test_node_sdk_byfn(self):
    #     '''
    #      In this node_sdk_byfn test, we pull published docker images from
    #      docker hub account and verify integration tests.
    #
    #      Passing criteria: Underlying node_sdk byfn tests are completed successfully
    #      with exit code 0
    #     '''
    #     logfile = open("output_node_sdk_byfn.log", "w")
    #     returncode = subprocess.call(
    #             "./run_node_sdk_byfn.sh",
    #             shell=True, stderr=subprocess.STDOUT, stdout=logfile)
    #     logfile.close()
    #     self.assertEqual(returncode, 0, msg="node_sdk_byfn test"
    #             " failed. \nPlease check the logfile "+logfile.name+" for more "
    #             "details.")
