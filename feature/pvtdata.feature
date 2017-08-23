# Copyright SecureKey Technologies Inc. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: FAB-1151 Private Data Channel

# @doNotDecompose
Scenario Outline: Test chaincode API support for private data partitions
  # NOTES:
  # - Requires cherry picks: https://gerrit.hyperledger.org/r/#/c/12257/

  Given I have a bootstrapped fabric network of type <type> using state-database <database>
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric-test/chaincodes/map" with args [] with name "marblecc"
  And I wait "<ccWaitTime>" seconds
  Then the chaincode is deployed

  # ----- PutPrivateData
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble1","red"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble2","blue"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col2","marble1","yellow"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col2","marble2","black"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col2","marble3","green"]
  And I wait "<ccWaitTime>" seconds

  # ----- GetPrivateData
  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col1","marble1"]
  Then a user receives a success response of "red"
  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col1","marble2"]
  Then a user receives a success response of "blue"
  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col2","marble1"]
  Then a user receives a success response of "yellow"
  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col2","marble2"]
  Then a user receives a success response of "black"
  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col2","marble3"]
  Then a user receives a success response of "green"

  # ----- GetPrivateDataByRange
  When a user queries on the chaincode named "marblecc" with args ["keysPrivate","col1","",""]
  Then a user receives a success response of ["marble1","marble2"]
  When a user queries on the chaincode named "marblecc" with args ["keysPrivate","col2","",""]
  Then a user receives a success response of ["marble1","marble2","marble3"]
  When a user queries on the chaincode named "marblecc" with args ["keysPrivate","col2","marble2","marble3"]
  Then a user receives a success response of ["marble2"]

  # ----- DelPrivateData
  When a user invokes on the chaincode named "marblecc" with args ["removePrivate","col1","marble1"]
  And I wait "<ccWaitTime>" seconds
  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col1","marble1"]
  Then a user receives a success response of ""

  # ----- PutPrivateData with composite key (index keys: color)
  # Populate collection: col3
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col3","marble1","ruby","color~key","red"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col3","marble2","rasberry","color~key","red"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col3","marble3","cherry","color~key","red"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col3","marble4","sapphire","color~key","blue"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col3","marble5","cyan","color~key","blue"]
  # Populate collection: col4
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble1","amber","color~key","yellow"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble2","gold","color~key","yellow"]
  And I wait "<ccWaitTime>" seconds

  # ----- GetPrivateDataByPartialCompositeKey (index keys: color)
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col3","color~key","red"]
  # The response should be in the format ["value1","value2",...] but the values may be in random order, thus we check the
  # length of the entire response and check that each value is contained within the string.
  Then a user receives a response containing a value of length 28
  And a user receives a response containing "ruby"
  And a user receives a response containing "rasberry"
  And a user receives a response containing "cherry"
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col3","color~key","blue"]
  Then a user receives a response containing a value of length 19
  And a user receives a response containing "sapphire"
  And a user receives a response containing "cyan"

  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col4","color~key","yellow"]
  Then a user receives a response containing a value of length 16
  And a user receives a response containing "amber"
  And a user receives a response containing "gold"

  # ----- PutPrivateData with composite key (index keys: color, size)
  # Populate collection: col4
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble1","big ruby","color~size~key","red","big"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble2","medium ruby","color~size~key","red","medium"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble3","small ruby","color~size~key","red","small"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble4","big rasberry","color~size~key","red","big"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble5","small rasberry","color~size~key","red","small"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble6","small cherry","color~size~key","red","small"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble7","small lemon","color~size~key","yellow","small"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col4","marble8","small banana","color~size~key","yellow","small"]

  # Populate collection: col5
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col5","marble1","big sapphire","color~size~key","blue","big"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col5","marble2","medium cyan","color~size~key","blue","medium"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivateComposite","col5","marble3","big cyan","color~size~key","blue","big"]
  And I wait "<ccWaitTime>" seconds

  # ----- GetPrivateDataByPartialCompositeKey (index keys: color, size)
  # Retrieve all red marbles on collection: col4
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col4","color~size~key","red"]
  Then a user receives a response containing a value of length 86
  And a user receives a response containing "big ruby"
  And a user receives a response containing "medium ruby"
  And a user receives a response containing "small ruby"
  And a user receives a response containing "big rasberry"
  And a user receives a response containing "small rasberry"
  And a user receives a response containing "small cherry"
  
  # Retrieve all yellow marbles on collection: col4
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col4","color~size~key","yellow"]
  Then a user receives a response containing a value of length 30
  And a user receives a response containing "small lemon"
  And a user receives a response containing "small banana"

  # Retrieve all big red marbles on collection: col4
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col4","color~size~key","red","big"]
  Then a user receives a response containing a value of length 27
  And a user receives a response containing "big ruby"
  And a user receives a response containing "big rasberry"

  # Retrieve all medium red marbles on collection: col4
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col4","color~size~key","red","medium"]
  Then a user receives a success response of ["medium ruby"]

  # Retrieve all medium red marbles on collection: col4
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col4","color~size~key","red","small"]
  Then a user receives a response containing a value of length 46
  And a user receives a response containing "small ruby"
  And a user receives a response containing "small rasberry"
  And a user receives a response containing "small cherry"

  # Retrieve all big blue marbles on collection: col5
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col5","color~size~key","blue","big"]
  Then a user receives a response containing a value of length 27
  And a user receives a response containing "big sapphire"
  And a user receives a response containing "big cyan"

  # Retrieve all medium blue marbles on collection: col5
  When a user queries on the chaincode named "marblecc" with args ["getPrivateComposite","col5","color~size~key","blue","medium"]
  Then a user receives a success response of ["medium cyan"]

  Examples:
    | type  | waitTime | ccWaitTime | database|
    | solo  |    20    |    15      | leveldb |
    | kafka |    30    |    15      | leveldb |
    | solo  |    20    |    15      | couchdb |
    | kafka |    30    |    15      | couchdb |

# @doNotDecompose
Scenario Outline: Test rich queries in chaincode private data partitions
  # NOTES:
  # - Requires cherry picks: https://gerrit.hyperledger.org/r/#/c/12257/

  Given I have a bootstrapped fabric network of type <type> using state-database couchdb
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric-test/chaincodes/map" with args [] with name "marblecc"
  And I wait "<ccWaitTime>" seconds
  Then the chaincode is deployed

  # ----- PutPrivateData
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble1","{\\"name\\":\\"big red\\",\\"color\\":\\"red\\",\\"size\\":100}"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble2","{\\"name\\":\\"medium red\\",\\"color\\":\\"red\\",\\"size\\":50}"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble3","{\\"name\\":\\"small red\\",\\"color\\":\\"red\\",\\"size\\":10}"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble4","{\\"name\\":\\"big blue\\",\\"color\\":\\"blue\\",\\"size\\":100}"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble5","{\\"name\\":\\"medium blue\\",\\"color\\":\\"blue\\",\\"size\\":50}"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble6","{\\"name\\":\\"small blue\\",\\"color\\":\\"blue\\",\\"size\\":10}"]

  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col2","marble1","{\\"name\\":\\"big yellow\\",\\"color\\":\\"yellow\\",\\"size\\":10}"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col2","marble2","{\\"name\\":\\"medium yellow\\",\\"color\\":\\"yellow\\",\\"size\\":50}"]
  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col2","marble3","{\\"name\\":\\"small yellow\\",\\"color\\":\\"yellow\\",\\"size\\":100}"]
  And I wait "<ccWaitTime>" seconds

  # ----- GetPrivateDataQueryResult
  When a user queries on the chaincode named "marblecc" with args ["queryPrivate","col1","{\\"selector\\":{\\"name\\":{\\"\$eq\\":\\"small blue\\"}}}"]
  Then a user receives a success response of ["marble6"]
  When a user queries on the chaincode named "marblecc" with args ["queryPrivate","col2","{\\"selector\\":{\\"name\\":{\\"\$eq\\":\\"small blue\\"}}}"]
  Then a user receives a success response of null
  When a user queries on the chaincode named "marblecc" with args ["queryPrivate","col2","{\\"selector\\":{\\"name\\":{\\"\$eq\\":\\"medium yellow\\"}}}"]
  Then a user receives a success response of ["marble2"]

  When a user queries on the chaincode named "marblecc" with args ["queryPrivate","col1","{\\"selector\\":{\\"color\\":{\\"\$eq\\":\\"red\\"}}}"]
  # The response should be in the format ["key1","key2",...] but the keys may be in random order, thus we check the
  # length of the entire response and check that each key is contained within the string.
  Then a user receives a response containing a value of length 31
  And a user receives a response containing "marble1"
  And a user receives a response containing "marble2"
  And a user receives a response containing "marble3"
  When a user queries on the chaincode named "marblecc" with args ["queryPrivate","col1","{\\"selector\\":{\\"size\\":{\\"\$gt\\":10}}}"]
  Then a user receives a response containing a value of length 41
  And a user receives a response containing "marble1"
  And a user receives a response containing "marble2"
  And a user receives a response containing "marble4"
  And a user receives a response containing "marble5"
  When a user queries on the chaincode named "marblecc" with args ["queryPrivate","col1","{\\"selector\\":{\\"color\\":{\\"\$eq\\":\\"blue\\"},\\"size\\":{\\"\$gt\\":10}}}"]
  Then a user receives a response containing a value of length 21
  And a user receives a response containing "marble4"
  And a user receives a response containing "marble5"
  When a user queries on the chaincode named "marblecc" with args ["queryPrivate","col2","{\\"selector\\":{\\"size\\":{\\"\$lt\\":100}}}"]
  Then a user receives a response containing a value of length 21
  And a user receives a response containing "marble1"
  And a user receives a response containing "marble2"

  Examples:
    | type  | waitTime | ccWaitTime |
    | solo  |    20    |    15      |
    | kafka |    30    |    15      |


# @doNotDecompose
Scenario Outline: Test private data dissemination
  # In this scenario, peer0 is stopped and then putPrivate is invoked on on peer1. Peer0 is then
  # started and a query is performed on peer0 to ensure that it has the private data. 

  # NOTES:
  # - Requires cherry picks: https://gerrit.hyperledger.org/r/#/c/12257/
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type> using state-database <database>
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric-test/chaincodes/map" with args [] with name "marblecc"
  And I wait "<ccWaitTime>" seconds
  Then the chaincode is deployed

  When "peer0.org1.example.com" is taken down

  When a user invokes on the chaincode named "marblecc" with args ["putPrivate","col1","marble2","black"] on "peer1.org1.example.com"
  And I wait "<ccWaitTime>" seconds

  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col1","marble2"] on "peer1.org1.example.com"
  Then a user receives a success response of "black" from "peer1.org1.example.com"

  When "peer0.org1.example.com" comes back up
  And I wait "15" seconds

  When a user queries on the chaincode named "marblecc" with args ["getPrivate","col1","marble2"] on "peer0.org1.example.com"
  Then a user receives a success response of "black" from "peer0.org1.example.com"

  Examples:
    | type  | waitTime | ccWaitTime | database|
    | solo  |    10    |    15      | leveldb |
    | kafka |    20    |    15      | leveldb |
    | solo  |    10    |    15      | couchdb |
    | kafka |    20    |    15      | couchdb |


@skip
Scenario: Test endorsement fulfillment of private data policies (including append-only)
  ## TODO


@skip
Scenario: Test ledger purge from private state db and write set storage based on block-to-live (BTL) policy
  ## TODO


@skip
Scenario: Ensure that the collection key/value hashes are correctly set on the public ledger
  ## TODO
