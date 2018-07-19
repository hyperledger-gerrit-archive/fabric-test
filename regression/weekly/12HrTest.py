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

TEST_PASS_STRING="RESULT=PASS"


######################################################################
### COUCHDB
######################################################################

class TimedRun_12Hr(unittest.TestCase):

    #@unittest.skip("skipping")
    def test_FAB_7204_samplejsCC_2chan_x_2_x_10tps(self):
        result = subprocess.check_output("./FAB-7204-4i.sh", shell=True)
        self.assertIn(TEST_PASS_STRING, result)
