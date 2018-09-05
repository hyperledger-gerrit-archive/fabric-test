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

class verify_versions(unittest.TestCase):
    def test_verifyVersion(self):
        '''
         In this make targets test, we execute version check to make sure
         the binaries version is correct.

         Passing criteria: make version test completed successfully with
         exit code 0
        '''
        logfile = open("output_verify_version_release_tests.log", "w")
        returncode = subprocess.call(
                "./run_verify_versions.sh",
                shell=True, stderr=subprocess.STDOUT, stdout=logfile)
        logfile.close()
        self.assertEqual(returncode, 0, msg="Verify versions test failed. "
                "\nPlease check the logfile " +logfile.name+" for more details.")
