#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Ledger Service
    As a user I want to be able to test private chaincode with private data that would not be stored in ledger


@skip
Scenario Outline: FAB-6036-1: Test marbles02_private initMarble, readMarble, deleteMarble, transferMarble, getMarblesByRange, stateTransfer
  #Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  Given I have a bootstrapped fabric network of type <type>
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric-test/chaincodes/marbles02_private" with args [""] with name "mycc"

  #These two marbles are used for getMarblesByRange
  When a user invokes on the chaincode named "mycc" with args ["initMarble","001m1","indigo","35","saleem","10"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","004m4","green","35","dire straits","20"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble1","red","35","tom","30"]
  And I wait "3" seconds

  When a user queries on the chaincode with args ["readMarble","marble1"] from "peer0.org1.example.com"
  Then a user receives a response containing "docType":"marble" from "peer0.org1.example.com"
  And a user receives a response containing "name":"marble1" from "peer0.org1.example.com"
  And a user receives a response containing "color":"red" from "peer0.org1.example.com"
  And a user receives a response containing "size":35 from "peer0.org1.example.com"
  And a user receives a response containing "owner":"tom" from "peer0.org1.example.com"
  When a user queries on the chaincode with args ["readMarblePrivateDetails","marble1"] from "peer0.org1.example.com"
  Then a user receives a response containing "docType":"marblePrivateDetails" from "peer0.org1.example.com"
  And a user receives a response containing "name":"marble1" from "peer0.org1.example.com"
  And a user receives a response containing "price":30 from "peer0.org1.example.com"

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble2","blue","55","jerry","40"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble2"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble2"
  And a user receives a response containing "color":"blue"
  And a user receives a response containing "size":55
  And a user receives a response containing "owner":"jerry"
  When a user queries on the chaincode named "mycc" with args ["readMarblePrivateDetails","marble2"]
  Then a user receives a response containing "docType":"marblePrivateDetails"
  And a user receives a response containing "name":"marble2"
  And a user receives a response containing "price":40

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble111","pink","55","jane","50"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble111"
  And a user receives a response containing "color":"pink"
  And a user receives a response containing "size":55
  And a user receives a response containing "owner":"jane"

#Test transferMarble
  When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble1","jerry","60"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble1"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble1"
  And a user receives a response containing "color":"red"
  And a user receives a response containing "size":35
  And a user receives a response containing "owner":"jerry"

#delete a marble
  When a user invokes on the chaincode named "mycc" with args ["delete","marble2"]
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble2"]
  Then a user receives an error response of status: 500
  And a user receives an error response of {"Error":"Marble does not exist: marble2"}
  And I wait "3" seconds

# Begin creating marbles to to test transferMarblesBasedOnColor
# In the results ownership of marbles is not changed since in privatecc this API is not supported
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble100","red","5","cassey","70"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble101","blue","6","cassey","80"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble200","purple","5","ram","90"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble201","blue","6","ram","100"]
  And I wait "5" seconds

  When a user invokes on the chaincode named "mycc" with args ["transferMarblesBasedOnColor","blue","jerry"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble100"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble100"
  And a user receives a response containing "color":"red"
  And a user receives a response containing "size":5
  And a user receives a response containing "owner":"cassey"


  When a user queries on the chaincode named "mycc" with args ["readMarble","marble101"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble101"
  And a user receives a response containing "color":"blue"
  And a user receives a response containing "size":6
  And a user receives a response containing "owner":"cassey"


  When a user queries on the chaincode named "mycc" with args ["readMarble","marble200"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble200"
  And a user receives a response containing "color":"purple"
  And a user receives a response containing "size":5
  And a user receives a response containing "owner":"ram"

  When a user queries on the chaincode named "mycc" with args ["readMarble","marble201"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble201"
  And a user receives a response containing "color":"blue"
  And a user receives a response containing "size":6
  And a user receives a response containing "owner":"ram"


# state transfer
#  When "peer1.org1.example.com" is taken down
# When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble111","jerry"]
#  And I wait "3" seconds
#  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"]
#  Then a user receives a response containing "docType":"marble"
#  And a user receives a response containing "name":"marble111"
#  And a user receives a response containing "color":"pink"
#  And a user receives a response containing "size":55
#  And a user receives a response containing "owner":"jerry"
#  And I wait "10" seconds

#  When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble111","tom"]
#  And I wait "3" seconds
#  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"]
#  Then a user receives a response containing "docType":"marble"
#  And a user receives a response containing "name":"marble111"
#  And a user receives a response containing "color":"pink"
#  And a user receives a response containing "size":55
#  And a user receives a response containing "owner":"tom"

#Given the initial non-leader peer of "org1" comes back up
#  When "peer1.org1.example.com" comes back up 
#  And I wait "5" seconds
#  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"] on the initial non-leader peer of "org1"
#  Then a user receives a response containing "docType":"marble"
#  And a user receives a response containing "name":"marble111"
#  And a user receives a response containing "color":"pink"
#  And a user receives a response containing "size":55
#  And a user receives a response containing "owner":"tom"

# Test getMarblesByRange
  When a user queries on the chaincode named "mycc" with args ["getMarblesByRange","001m1", "005m4"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"001m1"
  And a user receives a response containing "color":"indigo"
  And a user receives a response containing "size":35
  And a user receives a response containing "owner":"saleem"

  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"004m4"
  And a user receives a response containing "color":"green"
  And a user receives a response containing "size":35
  And a user receives a response containing "owner":"dire straits"

  # Test getHistoryForMarble not supported in privatecc
  When a user queries on the chaincode named "mycc" with args ["getHistoryForMarble","marble1"]
  And I wait "10" seconds
  Then a user receives a success response of []

  Examples:
   | type  | database |
   | kafka |  leveldb |
   | kafka |  couchdb |
   | solo  |  leveldb |
   | solo  |  couchdb |



@skip
Scenario Outline: FAB-6036-2: Test support of rich queries in SHIM API: queryMarbles and queryMarblesByOwner using marbles chaincode on couchdb
    Given I have a bootstrapped fabric network of type solo using state-database couchdb with tls
    When a user sets up a channel
    And a user deploys chaincode at path "<path>" with args [""] with language "<language>"

    When a user invokes on the chaincode with args ["initMarble","marble1","blue","35","tom","100"]
    When a user invokes on the chaincode with args ["initMarble","marble2","red","50","tom","200"]
    And I wait "3" seconds
    When a user queries on the chaincode with args ["readMarble","marble1"]
    Then a user receives a response containing "name":"marble1"
    And a user receives a response containing "owner":"tom"

    When a user queries on the chaincode with args ["readMarble","marble2"]
    Then a user receives a response containing "name":"marble2"
    And a user receives a response containing "owner":"tom"

    # queryMarblesByOwner
    When a user queries on the chaincode with args ["queryMarblesByOwner","tom"]
    Then a user receives a response containing "Key":"marble1"
    And a user receives a response containing "name":"marble1"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "Key":"marble2"
    And a user receives a response containing "name":"marble2"

    # queryMarbles
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble1"
    And a user receives a response containing "name":"marble1"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "Key":"marble2"
    And a user receives a response containing "name":"marble2"
    When a user queries on the chaincode named "mycc" with args ["readMarblePrivateDetails","marble1"]
    Then a user receives a response containing "docType":"marblePrivateDetails"
    And a user receives a response containing "name":"marble1"
    And a user receives a response containing "price":100
    When a user queries on the chaincode named "mycc" with args ["readMarblePrivateDetails","marble2"]
    Then a user receives a response containing "docType":"marblePrivateDetails"
    And a user receives a response containing "name":"marble2"
    And a user receives a response containing "price":200

    # queryMarbles on more than one selector
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"red\\"}}"]

    Then a user receives a response containing "Key":"marble2"
    And a user receives a response containing "name":"marble2"
    And a user receives a response containing "color":"red"
    And a user receives a response containing "owner":"tom"
    Then a user receives a response not containing "Key":"marble1"
    And a user receives a response not containing "color":"blue"

    When a user invokes on the chaincode with args ["transferMarble","marble1","jerry"]
    And I wait "3" seconds
    And a user queries on the chaincode with args ["readMarble","marble1"]
    Then a user receives a response containing "docType":"marble"
    And a user receives a response containing "name":"marble1"
    And a user receives a response containing "color":"blue"
    And a user receives a response containing "size":35
    And a user receives a response containing "owner":"jerry"
    When a user invokes on the chaincode with args ["transferMarble","marble2","jerry"]
    And I wait "3" seconds
    And a user queries on the chaincode with args ["readMarble","marble2"]
    Then a user receives a response containing "docType":"marble"
    And a user receives a response containing "color":"red"
    And a user receives a response containing "size":50
    And a user receives a response containing "owner":"jerry"

    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a success response of []
Examples:
    |                             path                                   | language |
    | github.com/hyperledger/fabric-test/chaincodes/marbles02_private    | GOLANG   |
