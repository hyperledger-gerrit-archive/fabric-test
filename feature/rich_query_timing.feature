#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: testing rich query timing

@daily
Scenario Outline: FAB-6256: Test rich queries using marbles chaincode using <language>
    Given I have a bootstrapped fabric network of type solo using state-database couchdb with tls
    When a user sets up a channel
    And a user deploys chaincode at path "<path>" with args [""] with language "<language>"

    When a user invokes on the chaincode with args ["initMarble","marble1","blue","35","jane"]
    And I wait "3" seconds
    When a user queries on the chaincode with args ["readMarble","marble1"]
    Then a user receives a response containing "name":"marble1"
    And a user receives a response containing "owner":"jane"

    When a user invokes 500 times using chaincode named "mycc" with incremental args and 100 of them with owner "tom"
    And I wait "3" seconds

    # queryMarblesByOwner
    When a user queries on the chaincode with args ["queryMarblesByOwner","tom"]
    Then a user receives a response containing "Key":"marble402"
    And a user receives a response containing "name":"marble402"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "Key":"marble501"
    And a user receives a response containing "name":"marble501"

    # queryMarbles
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble402"
    And a user receives a response containing "name":"marble402"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "Key":"marble501"
    And a user receives a response containing "name":"marble501"

    And I wait "30000" seconds

Examples:
    |                             path                              | language |
    | github.com/hyperledger/fabric/examples/chaincode/go/marbles02 | GOLANG   |
