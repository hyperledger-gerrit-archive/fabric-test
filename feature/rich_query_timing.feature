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

    #First set of invoke+Query for sanity check
    When a user invokes on the chaincode with args ["initMarble","marble0","blue","35","jane"]
    And I wait "3" seconds
    When a user queries on the chaincode with args ["readMarble","marble0"]
    Then a user receives a response containing "name":"marble0"
    And a user receives a response containing "owner":"jane"

    #Bulk invokes and queries follow
    When a user invokes marble 1 to 50 with the last 10 of them with owner "tom", color "pinkish" and size "30"
    And I wait "3" seconds

    # queryMarbles
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble41"
    And a user receives a response containing "name":"marble41"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "Key":"marble50"
    And a user receives a response containing "name":"marble50"

    When a user invokes marble 51 to 100 with the last 40 of them with owner "tom", color "blue" and size "30"
    And I wait "3" seconds

    # queryMarbles
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}{\\"color\\":\\"blue\\"}}"]
    Then a user receives a response containing "Key":"marble91"
    And a user receives a response containing "name":"marble91"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "Key":"marble100"
    And a user receives a response containing "name":"marble100"

    And I wait "30000" seconds

Examples:
    |                             path                              | language |
    | github.com/hyperledger/fabric/examples/chaincode/go/marbles02 | GOLANG   |
