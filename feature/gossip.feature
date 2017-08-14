# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Gossip Service
    As a user I expect the gossip component work correctly

@daily
Scenario Outline: [FAB-4663] A non-leader peer goes down temporarily, is expected to catch up and have all missing blocks eventually
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "5" seconds
  Then the chaincode is deployed
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
  And a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 990

  Given the initial non-leader peer of "org1" is taken down
  And I wait "10" seconds
  ## Now do 5 invoke-queries in leader peer
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial elected-leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial elected-leader peer of "org1"
  Then a user receives a success response of 980 from the initial elected-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on the initial elected-leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial elected-leader peer of "org1"
  Then a user receives a success response of 960 from the initial elected-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on the initial elected-leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial elected-leader peer of "org1"
  Then a user receives a success response of 930 from the initial elected-leader peer of "org1"

  Given the initial non-leader peer of "org1" comes back up
  And I wait "10" seconds

  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 930 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","40"] on the initial non-leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial elected-leader peer of "org1"
  Then a user receives a success response of 890 from the initial elected-leader peer of "org1"

  Examples:
    | type  | waitTime |
    | solo  |    5     |
    | kafka |    10    |
