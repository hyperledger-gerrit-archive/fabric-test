# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: Bootstrap Service
    As a user I want to be able start and setup a fabric Network

#@doNotDecompose
Scenario Outline: FAB-1111: Test with Fabric-CA
    #Given I bootstrap a fabric-ca server with tls
    #Given I have a fabric-ca bootstrapped fabric network of type <type> with tls
    Given I have a bootstrapped fabric network of type <type> with tls
    And I enroll the following users using fabric-ca
         | username  |   organization   | password |  role  |
         |  latitia  | org1.example.com |  h3ll0   | admin  |
         |   scott   | org1.example.com |  th3r3   | member |
         |   adnan   | org2.example.com |  wh@tsup | member |
    When a user "latitia" sets up a channel
    #When an admin sets up a channel
  And an admin deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd" with args ["init","a","1000","b","2000"] with name "mycc"
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user "latitia" queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user "adnan" invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on peer0.org2.example.com
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 990
  When a user "latitia" queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 990
    #And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init", "a", "1000" , "b", "2000"] with name "cc1" on channel "chn1"
    When a user "latitia" sets up a channel named "chn2"
    And an admin deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/map" with args ["init"] with name "cc2" on channel "chn2"
    When a user "adnan" invokes on the channel "chn2" using chaincode named "cc2" with args ["put", "a", "1000"] on "peer0.org2.example.com"
    And I wait "5" seconds
    And a user "latitia" queries on the channel "chn2" using chaincode named "cc2" with args ["get", "a"]
    # the "map" chaincode adds quotes around the result
    Then a user receives a success response of "1000"
    When a user invokes on the channel "chn2" using chaincode named "cc2" with args ["put", "b", "2000"]
    And I wait "5" seconds
    And a user queries on the channel "chn2" using chaincode named "cc2" with args ["get", "b"] on "peer0.org2.example.com"
    # the "map" chaincode adds quotes around the result
    Then a user receives a success response of "2000" from "peer0.org2.example.com"
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


@doNotDecompose
@revoke
Scenario Outline: FAB-6499: Interoperability Test using <type> based orderer
    Given I have a bootstrapped fabric network of type <type> using state-database <database> with tls
    And I use the <interface> interface
    And I enroll the following users using fabric-ca
         | username  |   organization   | password |  role  | certType |
         |  latitia  | org1.example.com |  h3ll0   | admin  |   x509   |
         |   scott   | org2.example.com |  th3r3   | member |   x509   |
         |   adnan   | org1.example.com |  wh@tsup | member |   x509   |
    When an admin sets up a channel
    #When a user "latitia" sets up a channel
    And an admin deploys chaincode at path "<path>" with args ["init","a","1000","b","2000"] with name "mycc" with language "<language>"
    And I wait "5" seconds
    When a user "adnan" queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 1000
    And I wait "5" seconds
    When a user "adnan" invokes on the chaincode with args ["invoke","a","b","10"]
    And I wait "5" seconds
    When a user "scott" queries on the chaincode with args ["query","a"] from "peer0.org2.example.com"
    Then a user receives a success response of 990 from "peer0.org2.example.com"
    When a user "scott" invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on "peer0.org2.example.com"
    And I wait "5" seconds
    When a user "latitia" queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 980

    When an admin revokes the user "adnan" from org "org1.example.com"
    #And all organization admins sign the updated channel config
    #And the admin updates the channel using peer "peer0.org1.example.com"
    Then the "peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/crls/crl.pem" file is generated
Examples:
    | type  | database | interface  |                          path                                     | language |
    #| solo  | leveldb  | NodeJS SDK | github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd |  GOLANG  |
    #| kafka | couchdb  |    CLI     | github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd |  GOLANG  |
    #| solo | couchdb  |    CLI     | github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd |  GOLANG  |
    #| solo  | couchdb  |    CLI     |        ../../fabric-test/chaincodes/example02/node                |   NODE   |
    #| kafka | leveldb  | NodeJS SDK |        ../../fabric-test/chaincodes/example02/java                |   JAVA   |
    #| kafka | couchdb  |  Java SDK  |        ../../fabric-test/chaincodes/example02/node                |   NODE   |
    | kafka | couchdb  |  Java SDK  | github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd |  GOLANG  |


@doNotDecompose
@daily
Scenario Outline: FAB-IDEM: Identity Mixer Test using <type> based orderer
    Given an admin creates an idemix MSP for organization "org1.example.com"
    Given I have a bootstrapped fabric network of type <type> using state-database <database> with tls
    And I use the <interface> interface
    And I enroll the following users using fabric-ca
         | username  |   organization   | password |  role  | certType |
         |  latitia  | org1.example.com |  h3ll0   | admin  |  idemix  |
         |   scott   | org2.example.com |  th3r3   | member |  idemix  |
         |   adnan   | org1.example.com |  wh@tsup | member |  idemix  |
    When an admin sets up a channel
    And an admin deploys chaincode at path "<path>" with args ["init","a","1000","b","2000"] with name "mycc" with language "<language>"
    And I wait "5" seconds
    When a user "adnan" queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 1000
    And I wait "5" seconds
    When a user "adnan" invokes on the chaincode with args ["invoke","a","b","10"]
    And I wait "5" seconds
    When a user "scott" queries on the chaincode with args ["query","a"] from "peer0.org2.example.com"
    Then a user receives a success response of 990 from "peer0.org2.example.com"
    When a user "scott" invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on peer0.org2.example.com
    And I wait "5" seconds
    When a user "latitia" queries on the chaincode with args ["query","a"]
    Then a user receives a success response of 980
Examples:
    | type  | database | interface  |                                     path                                                | language |
    #| solo  | leveldb  | NodeJS SDK |            github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd            |  GOLANG  |
    #| kafka | couchdb  |    CLI     |            github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd            |  GOLANG  |
    | kafka | couchdb  |  Java SDK  | github.com/hyperledger/fabric-sdk-java/chaincode/gocc/sample1/src/github.com/example_cc |  GOLANG  |
    #| kafka | couchdb  |  Java SDK  |            github.com/hyperledger/fabric/examples/chaincode/go/example02/cmd            |  GOLANG  |
    #| solo  | couchdb  |    CLI     |                   ../../fabric-test/chaincodes/example02/node                           |   NODE   |
    #| kafka | leveldb  | NodeJS SDK |                   ../../fabric-test/chaincodes/example02/java                           |   JAVA   |
    #| kafka | couchdb  |  Java SDK  |                   ../../fabric-test/chaincodes/example02/node                           |   NODE   |


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
