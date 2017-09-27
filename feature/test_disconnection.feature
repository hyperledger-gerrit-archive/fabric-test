# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Disconnect Survival
    As a user I expect the peer to survive temporary network hiccups

  #@doNotDecompose
Scenario: A peer disconnects, comes back up, is able to resume regular operation
  Given I have a bootstrapped fabric network of type kafka
  And I wait "60" seconds
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "10" seconds
  Then the chaincode is deployed

  # do 1 set of invoke-query on the default peer (peer0.org1)
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer0.org1.example.com"
  Then a user receives a success response of 990 from "peer0.org1.example.com"

  ## Now disconnect a peer and then connect back
  When "peer0.org1.example.com" is taken down by doing a disconnect
  And I wait "15" seconds
  When "peer0.org1.example.com" comes back up by doing a connect
  And I wait "30" seconds

  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer0.org1.example.com"
  Then a user receives a success response of 960 from "peer0.org1.example.com"
