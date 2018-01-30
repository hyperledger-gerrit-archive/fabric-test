#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Testing Fabric CouchDB indexing
  Scenario Outline: <jira_num>: Test CouchDB indexing using marbles chaincode using <language> with 3 channels and 3 indexes
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    When a user imports index definition from "/var/hyperledger/sampleCouchDBIndexes/indexColorOnly.json" to the chaincode at path "<path>"
    And a user imports index definition from "/var/hyperledger/sampleCouchDBIndexes/indexSizeOnly.json" to the chaincode at path "<path>"
    And I wait "10" seconds
    # set up 3 channels, 1  cc each
    And a user sets up a channel named "mychannel1"
    And a user sets up a channel named "mychannel2"
    And a user sets up a channel named "mychannel3"
    And a user deploys chaincode at path "<path>" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"
    And a user deploys chaincode at path "<path>" with args [""] with name "mycc2" with language "<language>" on channel "mychannel2"
    And a user deploys chaincode at path "<path>" with args [""] with name "mycc3" with language "<language>" on channel "mychannel3"

    #Check index in every cc in every channel
    When a user requests to get the index named "indexColorDDoc" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.color":"asc"}] from the couchDB container

    When a user requests to get the index named "indexColorDDoc" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.color":"asc"}] from the couchDB container

    When a user requests to get the index named "indexColorDDoc" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.color":"asc"}] from the couchDB container

    When a user requests to get the index named "indexSizeDDoc" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.size":"asc"}] from the couchDB container

    When a user requests to get the index named "indexSizeDDoc" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.size":"asc"}] from the couchDB container

    When a user requests to get the index named "indexSizeDDoc" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.size":"asc"}] from the couchDB container

    When a user requests to get the index named "indexOwnerDoc" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.owner":"asc"}] from the couchDB container

    When a user requests to get the index named "indexOwnerDoc" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.owner":"asc"}] from the couchDB container

    When a user requests to get the index named "indexOwnerDoc" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"data.owner":"asc"}] from the couchDB container

Examples:
    |                             path                              | language |  jira_num   |
    | github.com/hyperledger/fabric/examples/chaincode/go/marbles02   | GOLANG   |  FAB-7253   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/node/ | NODE     |  FAB-7256   |

@doNotDecompose
  Scenario Outline: <jira_num>: Test CouchDB indexing using marbles chaincode using <language> with 1 channels and 3 selectors
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    And I wait "10" seconds
    When a user defines a couchDB index named indexOwnerOnly with design document name "indexOwnerDoc9" containing the fields "owner" to the chaincode at path "<path>"

    # set up 1 channels, 1  cc each
    When a user sets up a channel named "mychannel1"
    And a user deploys chaincode at path "<path>" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"
    And I wait "10" seconds

    #Check index in every cc in every channel
    When a user requests to get the index named "indexOwnerDoc" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["fields":{"docType":"asc","owner":"asc"}] from the couchDB container

Examples:
    |                             path                                | language |  jira_num   |
    #   | github.com/hyperledger/fabric/examples/chaincode/go/marbles02   | GOLANG   |  FAB-7251   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/go    | GOLANG   |  FAB-7251   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/node  | NODE     |  FAB-7254   |
