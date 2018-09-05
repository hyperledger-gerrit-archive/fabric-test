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

class make_targets(unittest.TestCase):
    def test_makeVersion(self):
        '''
         In this make targets test, we execute version check to make sure binaries version
         is correct.

         Passing criteria: make version test completed successfully with
         exit code 0
        '''
        logfile = open("output_make_version_release_tests.log", "w")
        returncode = subprocess.call(
                "./run_make_targets.sh makeVersion",
                shell=True, stderr=subprocess.STDOUT, stdout=logfile)
        logfile.close()
        self.assertEqual(returncode, 0, msg="Run make version target "
                "make version target tests failed. \nPlease check the logfile ")
