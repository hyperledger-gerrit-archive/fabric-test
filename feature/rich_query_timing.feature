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
    And I wait "3" seconds

    #Bulk invokes part 1
    When a user invokes marble 1 to 100 with the last 20 of them with owner "tom", color "pinkish" and size "30"
    And I wait "3" seconds

    # queryMarbles-single
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble81"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble100"

    # queryMarbles-single-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble81"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble100"

    # queryMarbles-4field
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"pinkish\\",\\"size\\":30,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble81"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble100"

    And I wait "5" seconds

    # queryMarbles-4field-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"pinkish\\",\\"size\\":30,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble81"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble100"

    #Bulk invokes part 2
    When a user invokes marble 101 to 500 with the last 100 of them with owner "tom", color "feroza" and size "40"
    And I wait "3" seconds

    # queryMarbles-single
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble401"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble500"

    # queryMarbles-single-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble401"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble500"

    # queryMarbles-4field
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"feroza\\",\\"size\\":40,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble401"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble500"

    And I wait "5" seconds

    # queryMarbles-4field-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"feroza\\",\\"size\\":40,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble401"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble500"


    #Bulk invokes part 3
    When a user invokes marble 501 to 1000 with the last 100 of them with owner "tom", color "cream" and size "50"
    And I wait "3" seconds

    # queryMarbles-single
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble1000"

    # queryMarbles-single-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble1000"

    # queryMarbles-4field
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"cream\\",\\"size\\":50,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble1000"

    And I wait "5" seconds

    # queryMarbles-4field-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"cream\\",\\"size\\":50,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble1000"


    #Bulk invokes part 4
    When a user invokes marble 1001 to 10000 with the last 100 of them with owner "tom", color "paste" and size "60"
    And I wait "3" seconds

    # queryMarbles-single
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble9901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble10000"

    # queryMarbles-single-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a response containing "Key":"marble9901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble10000"

    # queryMarbles-4field
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"paste\\",\\"size\\":60,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble9901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble10000"

    And I wait "5" seconds

    # queryMarbles-4field-again
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\",\\"color\\":\\"paste\\",\\"size\\":60,\\"docType\\":\\"marble\\"}}"]
    Then a user receives a response containing "Key":"marble9901"
    And a user receives a response containing "owner":"tom"
    And a user receives a response containing "name":"marble10000"





    And I wait "300000" seconds

Examples:
    |                             path                              | language |
    | github.com/hyperledger/fabric/examples/chaincode/go/marbles02 | GOLANG   |
