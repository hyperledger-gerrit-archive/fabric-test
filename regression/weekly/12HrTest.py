# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

######################################################################
# To execute:
# Install: sudo apt-get install python python-pytest
# Run on command line: py.test -v --junitxml results.xml ./12HrTest.py

import unittest
import subprocess

scenarios_directory = '../../tools/PTE/CITest/scenarios'
nl_directory = '../../tools/NL'

class TimedRun_12Hr(unittest.TestCase):

    #@unittest.skip("skipping")
    def test_FAB_7204_samplejsCC_2chan_x_2_x_10tps(self):
        returncode = subprocess.check_output("./FAB-7204-4i.sh", cwd=scenarios_directory, shell=True)
        self.assertEqual(returncode, 0, msg="Test Failed; check for errors in fabric-test/tools/PTE/CITest/Logs/")

        returncode = subprocess.call("./networkLauncher.sh -a down", cwd=nl_directory, shell=True)
