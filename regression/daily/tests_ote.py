# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import unittest
import subprocess

tool_directory = '../../tools/OTE'

class perf_orderer(unittest.TestCase):

    def test_FAB_6996_solo_1ch(self):
        '''
         In this Performance test, we observe the performance (time to
         complete) sending 30000 transactions using producer clients to 
         solo orderer with default batchsize and default payload and get
         it delivered to delivered clients

         Passing criteria: Underlying OTE test completed successfully with
         total sent transactions=total received transactions 
        '''
        with open("output_FAB-6996.log", "w") as logfile:
            result = subprocess.check_output("./runote.sh -t FAB-6996",
                                            shell=True,
                                            stderr=subprocess.STDOUT,
                                            #stdout=subprocess.STDOUT,
                                            cwd=tool_directory)
            self.assertIn("PASS", result)
            logfile.write(result)
