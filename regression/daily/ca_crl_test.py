#!/usr/bin/python
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import subprocess
import unittest
from subprocess import check_output

class CaClusterTest(unittest.TestCase):

    def test_FAB7206CaCrlGeneration(self):
        createLog = 'mkdir -p /tmp/logs; chmod 777 /tmp/logs'
        startContainer = 'docker run -v $PWD/../../tools/CTE/:/tmp/test -v /tmp:/tmp/logs -v $PWD/../../fabric-ca:/opt/gopath/src/github.com/hyperledger/fabric-ca hyperledger/fabric-ca-fvt /tmp/test/crl_test.sh'
        command = createLog + ';' + startContainer
        output = check_output([command], shell=True)
        print output
        self.assertIn('RC: 0, gencrl PASSED', output)
