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

class fabcar_release_tests(unittest.TestCase):

    def test_fabcar(self):
        '''
         In this cli test, we execute the fabcar example on published release
         docker images and pull published fabric binaries and perform tests on
         fabric-samples repository.

         Passing criteria: fabcar release test completed successfully with
         exit code 0
        '''
        logfile = open("output_fabcar_release_test.log", "w")
        returncode = subprocess.call(
                "./run_fabcar_release_tests.sh",
                shell=True, stderr=subprocess.STDOUT, stdout=logfile)
        logfile.close()
        self.assertEqual(returncode, 0, msg="test_fabcar "
                "tests are failed. \nPlease check the logfile "
                +logfile.name+" for more details.")
