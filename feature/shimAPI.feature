#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: ShimAPI  
    As a user I want to be able to test all the API in SHIM interface. Here we build on top of existing marbles02_chaincode

@smoke
Scenario Outline: FAB-5791-1: Test marbles02 initMarble, readMarble, deleteMarble, transferMarble, getMarblesByRange, stateTransfer
# |  shim API in ChaincoderStubInterfaces	| Covered in shimInterfaceAPIDriver        |
# |        Init	                                |                init                      |
# |        Invoke	                        |               invoke                     |
# |        GetState 	                        | readMarble, initMarble, transferMarble   |
# |        PutState 	                        |    initMarble, transferMarble            |
# |        DelState 	                        |             deleteMarble                 |
# |        CreateCompositeKey 	                |       initMarble, deleteMarble           |
# |        SplitCompositeKey 	                |         transferMarblesBasedOnColor      |
# |        GetStateByRange 	                |         transferMarblesBasedOnColor      |
# |        GetQueryResult 	                | readMarbles,queryMarbles,queryMarblesByOwner  |
# |        GetHistoryForKey 	                |       getHistoryForMarble                |
# | GetStatePartialCompositeKeyQuery	        |   Yes - transferMarblesBasedOnColor      |

# |        GetArgs                              |              GetArgs                     |
# |        GetArgsSlice                         |              GetArgsSlice                |
# |        GetStringArgs                        |              GetStringArgs               |
# |        GetFunctionAndParameters             |              GetFunctionAndParameters    |

# |        GetBinding                           |              *GetBinding                 |
# |        GetCreator                           |              *GetCreator                 |
# |        GetTxTimeStamp                       |              *GetTxTimeStamp             |
# |        GetSignedProposal                    |              *GetSignedProposal          |
# |        GetTransient                         |              *GetTransient               |
# |        GetTxID                              |                                          |
# |        GetDecorations                       |                                          |
# |        SetEvent                             |                                          |

# |        InvokeChaincode                      |             ch_ex04 and ch_ex05          |
	
  Given I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  When a user deploys chaincode at path <chaincodePath> with args [""] with name "mycc"
  And I wait "5" seconds
  Then the chaincode is deployed


  #first two marbles are used for getMarblesByRange
  When a user invokes on the chaincode named "mycc" with args ["initMarble","001m1","indigo","35","saleem"]
  And I wait "10" seconds
  When a user invokes on the chaincode named "mycc" with args ["initMarble","004m4","green","35","dire straits"]

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble1","red","35","tom"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble1"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble1"
  And a user receives a response containing "color":"red"
  And a user receives a response containing "size":35
  And a user receives a response containing "owner":"tom"

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble2","blue","55","jerry"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble2"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble2"
  And a user receives a response containing "color":"blue"
  And a user receives a response containing "size":55
  And a user receives a response containing "owner":"jerry"

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble111","pink","55","jane"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble111"
  And a user receives a response containing "color":"pink"
  And a user receives a response containing "size":55
  And a user receives a response containing "owner":"jane"

#Test transferMarble
  When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble1","jerry"]
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
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble100","red","5","cassey"]
  And I wait "3" seconds

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble101","blue","6","cassey"]
  And I wait "3" seconds

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble200","purple","5","ram"]
  And I wait "3" seconds

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble201","blue","6","ram"]
  And I wait "3" seconds

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
  And a user receives a response containing "owner":"jerry"


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
  And a user receives a response containing "owner":"jerry"


# Test getMarblesByRange
  When a user queries on the chaincode named "mycc" with args ["getMarblesByRange","001m1", "005m4"]
  And I wait "3" seconds
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


  # Test getHistoryForMarble
  When a user queries on the chaincode named "mycc" with args ["getHistoryForMarble","marble1"]
  And I wait "10" seconds
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble1","color":"red","size":35,"owner":"tom"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"false"

  #delete a marble
  When a user invokes on the chaincode named "mycc" with args ["delete","marble201"]
  And I wait "20" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble201"]
  Then a user receives an error response of status: 500
  And a user receives an error response of {"Error":"Marble does not exist: marble201"}
  And I wait "3" seconds


  #Test getHistoryForDeletedMarble
  When a user queries on the chaincode named "mycc" with args ["getHistoryForMarble","marble201"]
  And I wait "10" seconds
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble201","color":"blue","size":6,"owner":"ram"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"false"
  And I wait "10" seconds
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble201","color":"blue","size":6,"owner":"ram"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"true"

  When a user queries on the chaincode named "mycc" with args ["getTxTimeStamp"]
  Then a user receives a success response of status: 200
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["getCreator"]
  When a user queries on the chaincode named "mycc" with args ["getBinding"]
  When a user queries on the chaincode named "mycc" with args ["getSignedProposal"]
  When a user queries on the chaincode named "mycc" with args ["getTransient"]


  Examples:
   | type  | database | waitTime |                      chaincodePath                                       |
   | kafka |  leveldb |   30     | "github.com/hyperledger/fabric-test/chaincodes/shimInterfaceAPIDriver"   |
   | kafka |  couchdb |   30     | "github.com/hyperledger/fabric-test/chaincodes/shimInterfaceAPIDriver"   |
   | solo  |  leveldb |   20     | "github.com/hyperledger/fabric-test/chaincodes/shimInterfaceAPIDriver"   |
   | solo  |  couchdb |   20     | "github.com/hyperledger/fabric-test/chaincodes/shimInterfaceAPIDriver"   |

@smoke
Scenario Outline: FAB-5791-2: Test rich queries using marbles chaincode using <language>
    Given I have a bootstrapped fabric network of type <type>  using state-database <database> with tls
    And I wait "20" seconds
    When a user sets up a channel
    And a user deploys chaincode at path "<path>" with args [""] with language "<language>"
    And I wait "15" seconds
    Then the chaincode is deployed

    When a user invokes on the chaincode with args ["initMarble","marble1","blue","35","tom"]
    And I wait "3" seconds
    When a user queries on the chaincode with args ["readMarble","marble1"]
    Then a user receives a response containing "name":"marble1"
    And a user receives a response containing "owner":"tom"

    When a user invokes on the chaincode with args ["initMarble","marble2","red","50","tom"]
    And I wait "3" seconds
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
  Examples:
    | type  | database | waitTime |                                  path                                  |
    | solo  |  couchdb |   20     |  "github.com/hyperledger/fabric-test/chaincodes/shimInterfaceDriver"   |
    | kafka |  couchdb |   30     |  "github.com/hyperledger/fabric-test/chaincodes/shimInterfaceDriver"   |
