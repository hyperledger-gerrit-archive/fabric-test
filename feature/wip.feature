# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: WIP
    As a user I want to be able have channels and chaincodes to execute

#@doNotDecompose
Scenario Outline: Test chaincode example02 using only node-SDK APIs deploy, invoke, and query
    Given I have a bootstrapped fabric network of type <type> <security>
    And I use the NodeJS SDK interface
    When a user sets up a channel
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
#    When a user queries on the chaincode named "mycc" with args ["query","a"]
#    Then a user receives a success response of 1000
    When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
    And a user queries on the chaincode named "mycc" with args ["query","a"]
    Then a user receives a success response of 990

    When "peer0.org2.example.com" is taken down
    And a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
    And I wait "5" seconds
    And "peer0.org2.example.com" comes back up
    And I wait "10" seconds
    And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer0.org2.example.com"
    Then a user receives a success response of 980 from "peer0.org2.example.com"
Examples:
    | type  |   security  |
    | solo  | without tls |
    | kafka |   with tls  |

