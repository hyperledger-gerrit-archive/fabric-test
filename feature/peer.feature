# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: Peer Service
    As a user I want to be able have channels and chaincodes to execute

#@doNotDecompose
@daily
Scenario Outline: FAB-3505: Test chaincode example02 deploy, invoke, and query, with <type> orderer
    Given I have a bootstrapped fabric network of type <type> <security>
    And I use the <interface> interface
    When a user sets up a channel
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
    When a user queries on the chaincode named "mycc" with args ["query","a"]
    Then a user receives a success response of 1000
    When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
    And I wait "5" seconds
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
    | type  |   security  |  interface |
    | solo  | without tls | NodeJS SDK |
    | kafka |   with tls  | NodeJS SDK |
    | solo  | without tls |     CLI    |
    | kafka |   with tls  |     CLI    |


@smoke
Scenario Outline: FAB-1440, FAB-3861: Basic Chaincode Execution - <type> orderer type, using <database>, <security>
    Given I have a bootstrapped fabric network of type <type> using state-database <database> <security>
    When a user sets up a channel
    And a user deploys chaincode
    When a user queries on the chaincode
    Then a user receives a success response of 100
    When a user invokes on the chaincode
    And I wait "5" seconds
    And a user queries on the chaincode
    Then a user receives a success response of 95
Examples:
    | type  | database |  security   |
    | solo  | leveldb  |  with tls   |
    | solo  | leveldb  | without tls |
    | solo  | couchdb  |  with tls   |
    | solo  | couchdb  | without tls |
    | kafka | leveldb  |  with tls   |
    | kafka | leveldb  | without tls |
    | kafka | couchdb  |  with tls   |
    | kafka | couchdb  | without tls |


@daily
Scenario Outline: FAB-3865: Multiple Channels Per Peer, with <type> orderer
    Given I have a bootstrapped fabric network of type <type>
    When a user sets up a channel named "chn1"
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init", "a", "1000" , "b", "2000"] with name "cc1" on channel "chn1"
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
    | kafka |


@daily
Scenario Outline: FAB-3866: Multiple Chaincodes Per Peer, with <type> orderer
    Given I have a bootstrapped fabric network of type <type>
    When a user sets up a channel
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/eventsender" with args [] with name "eventsender"
    When a user invokes on the chaincode named "eventsender" with args ["invoke", "test_event"]
    And I wait "5" seconds
    And a user queries on the chaincode named "eventsender" with args ["query"]
    Then a user receives a success response of {"NoEvents":"1"}
    When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init", "a", "1000" , "b", "2000"] with name "example02"
    When a user invokes on the chaincode named "example02" with args ["invoke", "a", "b", "10"]
    And I wait "5" seconds
    And a user queries on the chaincode named "example02" with args ["query", "a"]
    Then a user receives a success response of 990
    When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/map" with args ["init"] with name "map"
    When a user invokes on the chaincode named "map" with args ["put", "a", "1000"]
    And I wait "5" seconds
    And a user queries on the chaincode named "map" with args ["get", "a"]
    # the "map" chaincode adds quotes around the result
    Then a user receives a success response of "1000"
    When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/marbles02" with args [] with name "marbles"
    When a user invokes on the chaincode named "marbles" with args ["initMarble", "marble1", "blue", "35", "tom"]
    And I wait "5" seconds
    And a user invokes on the chaincode named "marbles" with args ["transferMarble", "marble1", "jerry"]
    And I wait "5" seconds
    And a user queries on the chaincode named "marbles" with args ["readMarble", "marble1"]
    Then a user receives a success response of {"docType":"marble","name":"marble1","color":"blue","size":35,"owner":"jerry"}
    When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/sleeper" with args ["1"] with name "sleeper"
    When a user invokes on the chaincode named "sleeper" with args ["put", "a", "1000", "1"]
    And I wait "5" seconds
    And a user queries on the chaincode named "sleeper" with args ["get", "a", "1"]
    Then a user receives a success response of 1000
Examples:
    | type  |
    | solo  |
    | kafka |

  Scenario: FAB-6333: A peer with chaincode container disconnects, comes back up, is able to resume regular operation
  Given I have a bootstrapped fabric network of type solo
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "10" seconds

  # do 1 set of invoke-query on peer1.org1
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on "peer1.org1.example.com"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer1.org1.example.com"
  Then a user receives a success response of 990 from "peer1.org1.example.com"

  ## Now disconnect a peer
  When "peer1.org1.example.com" is taken down by doing a disconnect
  And I wait "15" seconds

  # do 2 set of invoke-query on peer0.org1
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on "peer0.org1.example.com"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer0.org1.example.com"
  Then a user receives a success response of 970 from "peer0.org1.example.com"

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on "peer0.org1.example.com"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer0.org1.example.com"
  Then a user receives a success response of 940 from "peer0.org1.example.com"

  #bring back up the disconnected peer
  When "peer1.org1.example.com" comes back up by doing a connect
  And I wait "30" seconds

  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer1.org1.example.com"
  Then a user receives a success response of 940 from "peer1.org1.example.com"

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","40"] on "peer1.org1.example.com"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer1.org1.example.com"
  Then a user receives a success response of 900 from "peer1.org1.example.com"


@daily
Scenario Outline: FAB-7150: Test Mutual TLS/ClientAuth <security> with <type> based-orderer
  Given the CORE_PEER_TLS_CLIENTAUTHREQUIRED environment variable is "true"
  And the ORDERER_TLS_CLIENTAUTHREQUIRED environment variable is "true"
  And I have a bootstrapped fabric network of type <type> <security>
  And I use the <interface> interface
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 990

  When "peer0.org2.example.com" is taken down
  And a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
  And I wait "5" seconds
  And "peer0.org2.example.com" comes back up
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on "peer0.org2.example.com"
  Then a user receives a success response of 980 from "peer0.org2.example.com"


  When a user defines a couchDB index named indexColorOnly from indexColorDDoc documents containing the field "color" to the chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/marbles02"
  When a user defines a couchDB index named indexSizeOnly from indexSizeDDoc documents containing the field "size" to the chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/node"
  When a user defines a couchDB index named indexOwnerOnly from indexOwnerDoc documents containing the field "owner" to the chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/node"
  
Examples:
    | type  |   security  |  interface |
    | kafka |   with tls  | NodeJS SDK |
    | solo  |   with tls  | NodeJS SDK |
    | kafka |   with tls  |     CLI    |
    | solo  |   with tls  |     CLI    |
    | kafka | without tls |     CLI    |
    | solo  | without tls | NodeJS SDK |
