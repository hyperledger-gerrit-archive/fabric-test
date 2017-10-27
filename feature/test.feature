# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: Bootstrap Service
    As a user I want to be able start and setup a fabric Network

@doNotDecompose
Scenario Outline: FAB-1111: Test Fabric-CA
    Given I bootstrap a fabric-ca server with tls
    Given I have a fabric-ca bootstrapped fabric network of type <type> with tls
    #Given I have a bootstrapped fabric network of type <type> with tls
    And I register the orderers using fabric-ca
    And I register the peers using fabric-ca
    And I enroll the following users using fabric-ca
         | username  |   organization   | password |  role  |
         |   adnan   | org2.example.com |  wh@tsup | member |
         |   scott   | org1.example.com |  th3r3   | member |
         |  latitia  | org1.example.com |  h3ll0   | admin  |
    #And I have a bootstrapped fabric network of type <type>
    #When a user sets up a channel named "chn1"
    When a user "latitia" sets up a channel
    #And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init", "a", "1000" , "b", "2000"] with name "cc1" on channel "chn1"
    And a user deploys chaincode
    When a user sets up a channel named "chn2"
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/map" with args ["init"] with name "cc2" on channel "chn2"
    When a user invokes on the channel "chn2" using chaincode named "cc2" with args ["put", "a", "1000"]
    And I wait "5" seconds
    And a user queries on the channel "chn2" using chaincode named "cc2" with args ["get", "a"]
    # the "map" chaincode adds quotes around the result
    Then a user receives a success response of "1000"
    When a user invokes on the channel "chn2" using chaincode named "cc2" with args ["put", "b", "2000"]
    And I wait "5" seconds
    And a user queries on the channel "chn2" using chaincode named "cc2" with args ["get", "b"]
    # the "map" chaincode adds quotes around the result
    Then a user receives a success response of "2000"
    When a user invokes on the channel "chn1" using chaincode named "cc1" with args ["invoke", "a", "b", "10"]
    And I wait "5" seconds
    And a user queries on the channel "chn1" using chaincode named "cc1" with args ["query", "a"]
    Then a user receives a success response of 990
    When a user queries on the channel "chn2" using chaincode named "cc2" with args ["get", "a"]
    # the "map" chaincode adds quotes around the result
    Then a user receives a success response of "1000"
Examples:
    | type  |
    | solo  |
    #| kafka |


Scenario: Test Me
    Given I have a bootstrapped fabric network of type solo with tls
    When a user sets up a channel
    And a user deploys chaincode
    When a user queries on the chaincode
    Then a user receives a success response of 100
    When a user invokes on the chaincode
    And I wait "5" seconds
    And a user queries on the chaincode
    Then a user receives a success response of 95


@doNotDecompose
Scenario: Test Update
  Given I have a bootstrapped fabric network of type solo with tls
  When a user sets up a channel
  And a user deploys chaincode with args ["init","a","1000","b","2000"]
  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 990

  #When a user fetches genesis information from peer "peer0.org1.example.com"
  When an admin updates the channel config with {"org3.example.com": {}}
  And all peers sign the updated channel config
  And all peers update the channel
  When a user fetches genesis information from peer "peer0.org1.example.com"
