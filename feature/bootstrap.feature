# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: Bootstrapping Hyperledger Fabric
    As a user I want to be able to bootstrap my fabric network

@daily
Scenario: FAB-3635: Bootstrap Network from Configuration files
    Given I have a fabric config file
    When the network is bootstrapped for an orderer
    Then the "orderer.block" file is generated
    When the network is bootstrapped for a channel named "mychannel"
    Then the "mychannel.tx" file is generated

@daily
Scenario: FAB-3854: Ensure genesis block generated by configtxgen contains correct data
    Given I have a fabric config file
    When the network is bootstrapped for an orderer
    Then the "orderer.block" file is generated
    And the orderer block "orderer.block" contains MSP
    And the orderer block "orderer.block" contains root_certs
    And the orderer block "orderer.block" contains tls_root_certs
    And the orderer block "orderer.block" contains Writers
    And the orderer block "orderer.block" contains Readers
    And the orderer block "orderer.block" contains BlockValidation
    And the orderer block "orderer.block" contains HashingAlgorithm
    And the orderer block "orderer.block" contains OrdererAddresses
    And the orderer block "orderer.block" contains ChannelRestrictions
    And the orderer block "orderer.block" contains ChannelCreationPolicy
    And the orderer block "orderer.block" contains mod_policy
    When the network is bootstrapped for a channel named "mychannel"
    Then the "mychannel.tx" file is generated
    And the channel transaction file "mychannel.tx" contains Consortium
    And the channel transaction file "mychannel.tx" contains mychannel
    And the channel transaction file "mychannel.tx" contains Admins
    And the channel transaction file "mychannel.tx" contains Writers
    And the channel transaction file "mychannel.tx" contains Readers
    And the channel transaction file "mychannel.tx" contains mod_policy

@daily
Scenario Outline: FAB-3858: Verify crypto material (TLS) generated by cryptogen
    Given I have a crypto config file with <numOrgs> orgs, <peersPerOrg> peers, <numOrderers> orderers, and <numUsers> users
    When the crypto material is generated for TLS network
    Then crypto directories are generated containing tls certificates for <numOrgs> orgs, <peersPerOrg> peers, <numOrderers> orderers, and <numUsers> users
    Examples:
       | numOrgs | peersPerOrg | numOrderers | numUsers |
       |    2    |      2      |      3      |     1    |
       |    3    |      2      |      3      |     3    |

@daily
Scenario Outline: FAB-3856: Verify crypto material (non-TLS) generated by cryptogen
    Given I have a crypto config file with <numOrgs> orgs, <peersPerOrg> peers, <numOrderers> orderers, and <numUsers> users
    When the crypto material is generated
    Then crypto directories are generated containing certificates for <numOrgs> orgs, <peersPerOrg> peers, <numOrderers> orderers, and <numUsers> users
    Examples:
       | numOrgs | peersPerOrg | numOrderers | numUsers |
       |    2    |      2      |      3      |     1    |
       |    3    |      2      |      3      |     3    |
       |    2    |      3      |      4      |     4    |
       |    10   |      5      |      1      |     10   |

@smoke
Scenario: Access to the fabric protobuf files
    Given I test the access to the generated python protobuf files
    Then there are no errors

@smoke
Scenario: Basic operations to create a useful blockchain network
    Given I have a bootstrapped fabric network
    When a user sets up a channel
    And a user deploys chaincode

@smoke
Scenario: Setting of environment variables
    Given the KAFKA_DEFAULT_REPLICATION_FACTOR environment variable is 1
    And the CONFIGTX_ORDERER_BATCHTIMEOUT environment variable is 10 minutes
    And the CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT environment variable is 10
    And the CORE_LOGGING_GOSSIP environment variable is INFO
    And I have a bootstrapped fabric network of type kafka with tls
    Then the KAFKA_DEFAULT_REPLICATION_FACTOR environment variable is 1 on node "kafka1"
    And the CONFIGTX_ORDERER_BATCHTIMEOUT environment variable is 10 minutes on node "orderer0.example.com"
    And the CONFIGTX_ORDERER_BATCHSIZE_MAXMESSAGECOUNT environment variable is 10 on node "orderer1.example.com"
    And the ORDERER_GENERAL_TLS_ENABLED environment variable is true on node "orderer2.example.com"
    And the CORE_PEER_TLS_ENABLED environment variable is true on node "peer0.org1.example.com"
    And the CORE_LOGGING_GOSSIP environment variable is INFO on node "peer1.org2.example.com"


@daily
Scenario Outline: FAB-4776/FAB-4777: Bring up a kafka based network and check peers
    Given I have a bootstrapped fabric network of type kafka using state-database <database>
    When a user sets up a channel
    And a user deploys chaincode
    And the orderer node logs receiving the orderer bloc
    And a user queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 100
    When a user fetches genesis information from peer "peer1.org1.example.com" using "orderer0.example.com" to location "."
    Then the block file is fetched from peer "peer1.org1.example.com" at location "."
    When a user queries on the chaincode with args ["query","a"] from "peer1.org1.example.com"
    Then a user receives a success response of 100 from "peer1.org1.example.com"
    When a user queries on the chaincode with args ["query","a"] from "peer1.org1.example.com"
    Then a user receives a success response of 100 from "peer1.org1.example.com"
    When a user fetches genesis information from peer "peer1.org2.example.com" using "orderer1.example.com" to location "."
    Then the block file is fetched from peer "peer1.org2.example.com" at location "."
    When a user queries on the chaincode with args ["query","a"] from "peer1.org2.example.com"
    Then a user receives a success response of 100 from "peer1.org2.example.com"
Examples:
    | database |
    | leveldb  |
    | couchdb  |


@daily
Scenario: FAB-4773: Fetching of a channel genesis block
    Given I have a crypto config file with 2 orgs, 2 peers, 3 orderers, and 2 users
    And I have a fabric config file
    When the crypto material is generated for TLS network
    And the network is bootstrapped for an orderer
    And the network is bootstrapped for a channel named "mychannel"
    And I start a fabric network
    And a user creates a channel named "mychannel"
    And a user fetches genesis information for a channel "mychannel" from peer "peer1.org1.example.com" to location "."
    Then the file "mychannel.block" file is fetched from peer "peer1.org1.example.com" at location "."
