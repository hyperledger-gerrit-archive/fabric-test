#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Testing Fabric CouchDB indexing

@daily
  Scenario Outline: <jira_num>: Test CouchDB indexing using marbles chaincode using <language> with 1 channels and 1 index with 1 selector
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    When a user defines a couchDB index named index_behave_test with design document name "indexdoc_behave_test" containing the fields "size" to the chaincode at path "<index_path>"

    # set up 1 channels, 1  cc each
    When a user sets up a channel named "mychannel1"
    And a user deploys chaincode at path "<cc_path>" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"

    #Check index in every cc in every channel
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"size":"asc"}] from the couchDB container

Examples:
    |                             cc_path                            |                      index_path                              | language  |  jira_num   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/go   | github.com/hyperledger/fabric-samples/chaincode/marbles02/go | GOLANG    | FAB-7251    |
    | ../../fabric-samples/chaincode/marbles02/node                  | ../fabric-samples/chaincode/marbles02/node                   | NODE      | FAB-7254    |


@daily
  Scenario Outline: <jira_num>: Test CouchDB indexing using marbles chaincode using <language> with 3 channels and 1 index with 3 selectors
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    When a user defines a couchDB index named index_behave_test with design document name "indexdoc_behave_test" containing the fields "owner,docType,color" to the chaincode at path "<index_path>"

    # set up 1 channels, 1  cc each
    When a user sets up a channel named "mychannel1"
    And a user sets up a channel named "mychannel2"
    And a user sets up a channel named "mychannel3"
    And a user deploys chaincode at path "<cc_path>" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"
    And a user deploys chaincode at path "<cc_path>" with args [""] with name "mycc2" with language "<language>" on channel "mychannel2"
    And a user deploys chaincode at path "<cc_path>" with args [""] with name "mycc3" with language "<language>" on channel "mychannel3"

    #Check index in every cc in every channel
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

Examples:
    |                             cc_path                            |                      index_path                              | language  |  jira_num   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/go   | github.com/hyperledger/fabric-samples/chaincode/marbles02/go | GOLANG    |  FAB-7252   |
    | ../../fabric-samples/chaincode/marbles02/node                  | ../fabric-samples/chaincode/marbles02/node                   | NODE      |  FAB-7255   |


@daily
  Scenario Outline: <jira_num>: Test CouchDB indexing using marbles chaincode using <language> with 3 channels and 3 index with 1 selector
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    When a user defines a couchDB index named index_behave_test_1 with design document name "indexdoc_behave_test_1" containing the fields "owner" to the chaincode at path "<index_path>"
    And a user defines a couchDB index named index_behave_test_2 with design document name "indexdoc_behave_test_2" containing the fields "docType" to the chaincode at path "<index_path>"
    And a user defines a couchDB index named index_behave_test_3 with design document name "indexdoc_behave_test_3" containing the fields "color" to the chaincode at path "<index_path>"

    # set up 3 channels, 1  cc each
    When a user sets up a channel named "mychannel1"
    And a user sets up a channel named "mychannel2"
    And a user sets up a channel named "mychannel3"
    And a user deploys chaincode at path "<cc_path>" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"
    And a user deploys chaincode at path "<cc_path>" with args [""] with name "mycc2" with language "<language>" on channel "mychannel2"
    And a user deploys chaincode at path "<cc_path>" with args [""] with name "mycc3" with language "<language>" on channel "mychannel3"

    #Check index in every cc in every channel
    When a user requests to get the design doc "indexdoc_behave_test_1" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_1" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_1" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_2" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_2":{"map":{"fields":{"docType":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_2" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_2":{"map":{"fields":{"docType":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_2" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_2":{"map":{"fields":{"docType":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_3" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_3":{"map":{"fields":{"color":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_3" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_3":{"map":{"fields":{"color":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test_3" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_3":{"map":{"fields":{"color":"asc"}] from the couchDB container

Examples:
    |                             cc_path                            |                      index_path                              | language  |  jira_num   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/go   | github.com/hyperledger/fabric-samples/chaincode/marbles02/go | GOLANG    |  FAB-7253   |
    | ../../fabric-samples/chaincode/marbles02/node                  | ../fabric-samples/chaincode/marbles02/node                   | NODE      |  FAB-7256   |


  Scenario Outline: <jira_num>: Test CouchDB indexing using CC upgrade with marbles chaincode using <language> with 1 channel
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    When a user defines a couchDB index named index_behave_test with design document name "indexdoc_behave_test" containing the fields "owner,docType,color" to the chaincode at path "<index_path>"

    # set up 1 channels, 1 cc each
    When a user sets up a channel named "mychannel1"
    And a user deploys chaincode at path "<cc_path>" with version "0" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"

    #add another index and deploy version 1
    When a user defines a couchDB index named index_behave_test_v1 with design document name "indexdoc_behave_test_v1" containing the fields "owner" to the chaincode at path "<index_path>"
    And a user installs chaincode at path "<cc_path>" of language "<language>" as version "1" with args [""] with name "mycc1"
    And a user upgrades the chaincode with name "mycc1" on channel "mychannel1" to version "1" with args [""]

    #Check index in cc in channel
    When a user requests to get the design doc "indexdoc_behave_test_v1" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_v1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

Examples:
    |                             cc_path                            |                      index_path                              | language  |  jira_num   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/go   | github.com/hyperledger/fabric-samples/chaincode/marbles02/go | GOLANG    |  FAB-7263   |
    | ../../fabric-samples/chaincode/marbles02/node                  | ../fabric-samples/chaincode/marbles02/node                   | NODE      |  FAB-7268   |


@daily
  Scenario Outline: <jira_num>: Test CouchDB indexing using CC upgrade with marbles chaincode using <language> with 3 channels and 1 upgrade
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    When a user defines a couchDB index named index_behave_test with design document name "indexdoc_behave_test" containing the fields "owner,docType,color" to the chaincode at path "<index_path>"

    # set up 3 channels, 1  cc each
    When a user sets up a channel named "mychannel1"
    And a user sets up a channel named "mychannel2"
    And a user sets up a channel named "mychannel3"
    And a user deploys chaincode at path "<cc_path>" with version "0" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"
    And a user deploys chaincode at path "<cc_path>" with version "0" with args [""] with name "mycc2" with language "<language>" on channel "mychannel2"
    And a user deploys chaincode at path "<cc_path>" with version "0" with args [""] with name "mycc3" with language "<language>" on channel "mychannel3"

    #add another index and deploy version 1 in 1 channel/cc only
    When a user defines a couchDB index named index_behave_test_v1 with design document name "indexdoc_behave_test_v1" containing the fields "owner" to the chaincode at path "<index_path>"
    And a user installs chaincode at path "<cc_path>" of language "<language>" as version "1" with args [""] with name "mycc1"
    And a user upgrades the chaincode with name "mycc1" on channel "mychannel1" to version "1" with args [""]

    #Check index in channel1 with upgraded CC
    When a user requests to get the design doc "indexdoc_behave_test_v1" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_v1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

    #Check index in channel2 with non-upgraded CC
    When a user requests to get the design doc "indexdoc_behave_test_v1" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives error response of [{"error":"not_found","reason":"missing"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

    #Check index in channel3 with upgraded CC
    When a user requests to get the design doc "indexdoc_behave_test_v1" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives error response of [{"error":"not_found","reason":"missing"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

Examples:
    |                             cc_path                            |                      index_path                              | language  |  jira_num   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/go   | github.com/hyperledger/fabric-samples/chaincode/marbles02/go | GOLANG    |  FAB-7264   |
    | ../../fabric-samples/chaincode/marbles02/node                  | ../fabric-samples/chaincode/marbles02/node                   | NODE      |  FAB-7269   |


@daily
  Scenario Outline: <jira_num>: Test CouchDB indexing using CC upgrade with marbles chaincode using <language> with 3 channels and 3 upgrade
    Given I have a bootstrapped fabric network of type kafka using state-database couchdb with tls
    When a user defines a couchDB index named index_behave_test with design document name "indexdoc_behave_test" containing the fields "owner,docType,color" to the chaincode at path "<index_path>"

    # set up 3 channels, 1  cc each
    When a user sets up a channel named "mychannel1"
    And a user sets up a channel named "mychannel2"
    And a user sets up a channel named "mychannel3"
    And a user deploys chaincode at path "<cc_path>" with version "0" with args [""] with name "mycc1" with language "<language>" on channel "mychannel1"
    And a user deploys chaincode at path "<cc_path>" with version "0" with args [""] with name "mycc2" with language "<language>" on channel "mychannel2"
    And a user deploys chaincode at path "<cc_path>" with version "0" with args [""] with name "mycc3" with language "<language>" on channel "mychannel3"

    #add another index and deploy version 1 in all 3 channel-cc
    When a user defines a couchDB index named index_behave_test_v1 with design document name "indexdoc_behave_test_v1" containing the fields "owner" to the chaincode at path "<index_path>"
    And a user installs chaincode at path "<cc_path>" of language "<language>" as version "1" with args [""] with name "mycc1"
    And a user upgrades the chaincode with name "mycc1" on channel "mychannel1" to version "1" with args [""]
    And a user installs chaincode at path "<cc_path>" of language "<language>" as version "1" with args [""] with name "mycc2"
    And a user upgrades the chaincode with name "mycc2" on channel "mychannel2" to version "1" with args [""]
    And a user installs chaincode at path "<cc_path>" of language "<language>" as version "1" with args [""] with name "mycc3"
    And a user upgrades the chaincode with name "mycc3" on channel "mychannel3" to version "1" with args [""]

    #Check index in channel with upgraded CC
    When a user requests to get the design doc "indexdoc_behave_test_v1" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_v1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc1" in the channel "mychannel1" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

    #Check index in channel2 with non-upgraded CC
    When a user requests to get the design doc "indexdoc_behave_test_v1" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_v1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc2" in the channel "mychannel2" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

    #Check index in channel3 with upgraded CC
    When a user requests to get the design doc "indexdoc_behave_test_v1" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test_v1":{"map":{"fields":{"owner":"asc"}] from the couchDB container
    When a user requests to get the design doc "indexdoc_behave_test" for the chaincode named "mycc3" in the channel "mychannel3" and from the CouchDB instance "http://localhost:5984"
    Then a user receives success response of ["views":{"index_behave_test":{"map":{"fields":{"owner":"asc","docType":"asc","color":"asc"}] from the couchDB container

Examples:
    |                             cc_path                            |                      index_path                              | language  |  jira_num   |
    | github.com/hyperledger/fabric-samples/chaincode/marbles02/go   | github.com/hyperledger/fabric-samples/chaincode/marbles02/go | GOLANG    |  FAB-7265   |
    | ../../fabric-samples/chaincode/marbles02/node                  | ../fabric-samples/chaincode/marbles02/node                   | NODE      |  FAB-7270   |
