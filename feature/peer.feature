# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: Peer Service
    As a user I want to be able have channels and chaincodes to execute

#@doNotDecompose
@daily
Scenario Outline: FAB-3505: Test chaincode example02 deploy, invoke, and query, with <type> orderer
    Given I have a bootstrapped fabric network of type <type>
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
    | type  |
    | solo  |
    | kafka |


#@doNotDecompose
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

@skip
Scenario Outline: FAB-4776/FAB-4777: Bring up a kafka based network and check peers
    Given I have a bootstrapped fabric network of type kafka using database <database>
    When a user sets up a channel
    And a user deploys chaincode
    And a user queries on the chaincode with args ["query","a"]
    And a user receives a success response of 100
#    And I wait "30" seconds
#    When a user queries on the chaincode with args ["query","a"] from "peer0.org2.example.com"
#    Then a user receives a success response of 100 from "peer0.org2.example.com"
    And I wait "30" seconds
    And a user fetches genesis information from peer "peer1.org1.example.com" using "orderer0.example.com"
    When a user queries on the chaincode with args ["query","a"] from "peer1.org1.example.com"
    Then a user receives a success response of 100 from "peer1.org1.example.com"
    And I wait "30" seconds
    And a user fetches genesis information from peer "peer1.org2.example.com" using "orderer1.example.com"
    When a user queries on the chaincode with args ["query","a"] from "peer1.org2.example.com"
    Then a user receives a success response of 100 from "peer1.org2.example.com"
Examples:
    | database |
    | leveldb  |
    | couchdb  |


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
    Then a user receives a success response of 1000
    When a user invokes on the channel "chn2" using chaincode named "cc2" with args ["put", "b", "2000"]
    And I wait "5" seconds
    And a user queries on the channel "chn2" using chaincode named "cc2" with args ["get", "b"]
    Then a user receives a success response of 2000
    When a user invokes on the channel "chn1" using chaincode named "cc1" with args ["invoke", "a", "b", "10"]
    And I wait "5" seconds
    And a user queries on the channel "chn1" using chaincode named "cc1" with args ["query", "a"]
    Then a user receives a success response of 990
    When a user queries on the channel "chn2" using chaincode named "cc2" with args ["get", "a"]
    Then a user receives a success response of 1000
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
    Then a user receives a success response of 1000
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


@daily
Scenario: FAB-4773: Fetching of a channel genesis block
    Given I have a crypto config file with 2 orgs, 2 peers, 3 orderers, and 2 users
    And I have a fabric config file
    When the crypto material is generated for TLS network
    And the network is bootstrapped for an orderer
    And the network is bootstrapped for a channel named "mychannel"
    And I start a fabric network
    And a user creates a channel named "mychannel"
    And a user fetches genesis information for a channel "mychannel" from peer "peer1.org1.example.com"
    Then the file "mychannel.block" file is fetched from peer "peer1.org1.example.com"


Scenario: LMH-2468: Consensus Testing
    Given I have a bootstrapped fabric network of type kafka
    And I wait "60" seconds
    When a user sets up a channel
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
    And I wait "10" seconds
    And a user queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 1000

    # Build up a sizable blockchain, that vp3 will need to validate at startup
    When a user invokes 30 times using chaincode named "mycc" with args ["invoke","a","b","1"]
    And I wait "120" seconds
    And a user queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 970
    When a user queries on the chaincode with args ["query","a"] from "peer0.org2.example.com"
    Then a user receives a success response of 970 from "peer0.org2.example.com"
    When a user queries on the chaincode with args ["query","a"] from "peer1.org1.example.com"
    Then a user receives a success response of 970 from "peer1.org1.example.com"
    When a user queries on the chaincode with args ["query","a"] from "peer1.org2.example.com"
    Then a user receives a success response of 970 from "peer1.org2.example.com"

    Given "peer0.org2.example.com" is taken down
    # Invoke a transaction to get peer out of sync
    When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
    And I wait "10" seconds
    And a user queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 960

    Given "peer1.org1.example.com" is taken down
    When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
    And I wait "10" seconds
    And a user queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 950

    Given "peer1.org1.example.com" comes back up
    And I wait "30" seconds
    When a user queries on the chaincode with args ["query","a"] from "peer1.org1.example.com"
    Then a user receives a success response of 950 from "peer1.org1.example.com"

    # Be sure multiple identical invokes only register 1 of the same transaction
    When a user invokes 10 times using chaincode named "mycc" with args ["invoke","a","b","10"]
    And I wait "60" seconds
    And a user queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 940
    When a user queries on the chaincode with args ["query","a"] from "peer1.org1.example.com"
    Then a user receives a success response of 940 from "peer1.org1.example.com"
    When a user queries on the chaincode with args ["query","a"] from "peer1.org2.example.com"
    Then a user receives a success response of 940 from "peer1.org2.example.com"

    # Now start peer again
    Given "peer0.org2.example.com" comes back up
    And I wait "30" seconds
    When a user invokes using chaincode named "mycc" with args ["invoke","a","b","10"]
    And I wait "60" seconds
    And a user queries on the chaincode with args ["query","a"] from "peer0.org2.example.com"
    Then a user receives a success response of 930 from "peer0.org2.example.com"
