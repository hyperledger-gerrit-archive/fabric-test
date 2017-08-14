#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#!/usr/bin/python
# -*- coding: utf-8 -*-

######################################################################
# To execute:
# Install: sudo apt-get install python python-pytest
# Run on command line: py.test -v --junitxml results_auction_daily.xml testAuctionChaincode.py

import subprocess
import unittest
from subprocess import check_output
import shutil


class ChaincodeAPI(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.CHANNEL_NAME = 'channel'
        cls.CHANNELS = '1'
        cls.CHAINCODES = '1'
        cls.ENDORSERS = '4'
        check_output(['./generateCfgTrx.sh {0} {1}'.format(cls.CHANNEL_NAME, cls.CHANNELS)], cwd='../../envsetup', shell=True)
        check_output(['docker-compose -f docker-compose.yaml up -d'], cwd='../../envsetup', shell=True)

    @classmethod
    def tearDownClass(cls):
        check_output(['docker-compose -f docker-compose.yaml down'], cwd='../../envsetup', shell=True)
        delete_this = ['__pycache__', '.cache']
        for item in delete_this:
            shutil.rmtree(item,ignore_errors=True)

#################################################################################

    def runIt(self, command, scriptName):
        cmd = \
            '/opt/gopath/src/github.com/hyperledger/fabric/test/tools/auctionapp/%s %s %s %s %s %s' \
            % (
            scriptName,
            self.CHANNEL_NAME,
            self.CHANNELS,
            self.CHAINCODES,
            self.ENDORSERS,
            command,
            )
        output = \
            check_output(['docker exec cli bash -c "{0}"'.format(cmd)],
                         shell=True)
        return output

    def test_FAB3934_10_Create_Channel(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to creates channels
            Passing criteria: Creating Channel is successful
        '''
        output = self.runIt('createChannel', 'api_driver.sh')
        self.assertIn('Creating Channel is successful', output)


    def test_FAB3934_11_Join_Channel(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to join peers on all channels
            Passing criteria: Join Channel is successful
        '''
        output = self.runIt('joinChannel', 'api_driver.sh')
        self.assertIn('Join Channel is successful', output)


    def test_FAB3934_12_Install_Chaincode(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to install all chaincodes on all peers
            Passing criteria: Installing chaincode is successful
        '''
        output = self.runIt('installChaincode', 'api_driver.sh')
        self.assertIn('Installing chaincode is successful', output)


    def test_FAB3934_13_Instantiate_Chaincode(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to instantiate all chaincodes on all channels
            Passing criteria: Instantiating chaincode is successful
        '''
        output = self.runIt('instantiateChaincode', 'api_driver.sh')
        self.assertIn('Instantiating chaincode is successful', output)

    def test_FAB3934_14_Post_Users(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to submit users to the auction application
            Passing criteria: Posting Users transaction is successful
        '''
        output = self.runIt('postUsers', 'api_driver.sh')
        self.assertIn('Posting Users transaction is successful', output)

    def test_FAB3934_15_Get_Users(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to query users submitted to the auction application
            Passing criteria: Get Users transaction is successful
        '''
        output = self.runIt('getUsers', 'api_driver.sh')
        self.assertIn('Get Users transaction is successful', output)

    def test_FAB3934_16_Download_Images(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to download auction images on all chaincode containers
            Passing criteria: Download Images transaction is successful
        '''
        output = self.runIt('downloadImages', 'api_driver.sh')
        self.assertIn('Download Images transaction is successful',
                      output)

    def test_FAB3934_17_Post_Items(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to submit auction items for a user in the auction application
            Passing criteria: Post Items transaction is successful
        '''
        output = self.runIt('postItems', 'api_driver.sh')
        self.assertIn('Post Items transaction is successful', output)

    def test_FAB3934_18_Post_Auction(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to create auction for an item in the auction application
            Passing criteria: Post Auction transaction is successful
        '''
        output = self.runIt('postAuction', 'api_driver.sh')
        self.assertIn('Post Auction transaction is successful', output)

    def test_FAB3934_19_Open_Auction(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to open auction item for an item in the auction application
            Passing criteria: Open Auction transaction is successful
        '''
        output = self.runIt('openAuctionRequestForBids', 'api_driver.sh')
        self.assertIn('Open Auction transaction is successful', output)

    def test_FAB3934_20_Submit_Bids(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to submit bids for an item in the auction application
            Passing criteria: Submit Bids transaction is successful
        '''
        output = self.runIt('submitBids', 'api_driver.sh')
        self.assertIn('Submit Bids transaction is successful', output)

    def test_FAB3934_21_Close_Transfer_Auction(self):
        '''
            Network: 1 Ord, 2 Org, 4 Peers, 1 Chan, 1 CC
            Description: This test is used to close auction transfer item from a user to other user in the auction application
            Passing criteria: Close Auction transaction is successful
        '''
        output = self.runIt('closeAuction', 'api_driver.sh')
        self.assertIn('Close Auction/Transfer Item transaction(s) are successful', output)
