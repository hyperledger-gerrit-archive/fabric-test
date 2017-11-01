#!/usr/bin/python
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

import subprocess
import unittest
from subprocess import check_output

class FAB6863ClusterTest(unittest.TestCase):

    def runTest(self):
        command = 'docker run -v $GOPATH/src/github.com/hyperledger/fabric-ca:/opt/gopath/src/github.com/hyperledger/fabric-ca hyperledger/fabric-ca-fvt ./scripts/fvt/cluster_test.sh 4 4 8 128'
        output = check_output([command], shell=True)
        print output
        self.assertIn('RC: 0, ca_cluster PASSED', output)
