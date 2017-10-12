#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import subprocess

fca_sample_directory = '../../fabric-samples/fabric-ca'
#fca_sample_directory = '../../../fabric-samples/fabric-ca'

class ACL(unittest.TestCase):

    def test_FAB6490_Using_FCA_With_ACL_Permissioning(self):
        '''
         In this ACL test, we execute the fabric-ca sample that
         is located in the fabric-sample repository. This sample executes a
         "happy path" scenario to ensure that the when a user is given limited
         access, that the ACL rule is followed as expected.

         Passing criteria: The sample executes with a congratulatory message.
        '''
        output = subprocess.check_output(["./scripts/env.sh", "&&", "./start.sh"],
                                         shell=True, cwd=fca_sample_directory)
        self.assertNotIn("ERROR", output)
        with open(fca_sample_directory+"/data/logs/run.log", "r") as fd:
            log = fd.read()
        self.assertIn("Congratulations! The tests ran successfully.", log)

