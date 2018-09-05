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

    def test_byfn_cli_upgrade(self):
        '''
         In this cli test, we execute the byfn upgrade command to determine
         if byfn is successfully updated to the latest version
         
         Passing criteria: byfn upgrade completes successfully with
         exit code 0
        '''
        logfile = open("output_byfn_cli_upgrade.log", "w")
        returncode = subprocess.call(
                "./run_byfn_upgrade_release_test.sh",
                shell=True, stderr=subprocess.STDOUT, stdout=logfile)
        logfile.close()
        self.assertEqual(returncode, 0, msg="test_byfn_cli_upgrade "
                "tests are failed. \nPlease check the logfile "
                +logfile.name+" for more details.")
