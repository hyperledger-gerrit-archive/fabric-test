#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Chaincode Testing
    As a user I want to be able verify that I can execute different chaincodes

@daily
Scenario Outline: FAB-3511-1: Test chaincode fabric/examples/marbles02 
#includes tests for : initMarble, readMarble, transferMarble, transferMarblesBasedOnColor

  Given I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user deploys chaincode at path "github.com/hyperledger/fabric-test/feature/chaincode/marbles02_private" with args [""] with name "mycc"
#  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/marbles02_private" with args [""] with name "mycc"
  And I wait "10" seconds
  Then the chaincode is deployed

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble1","red","35","tom"]
  And I wait "30" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble1"]
  Then a user receives a success response of {"docType":"marble","name":"marble1","color":"red","size":35,"owner":"tom"}

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble2","blue","55","jerry"]
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble2"]
  Then a user receives a success response of {"docType":"marble","name":"marble2","color":"blue","size":55,"owner":"jerry"}

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble111","pink","55","jane"]
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"]
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"jane"}

  #Test transferMarble
  When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble1","jerry"]
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble1"]
  Then a user receives a success response of {"docType":"marble","name":"marble1","color":"red","size":35,"owner":"jerry"}

  #delete a marble
  When a user invokes on the chaincode named "mycc" with args ["delete","marble2"]
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble2"]
  Then a user receives an error response of status: 500
  And a user receives an error response of {"Error":"Marble does not exist: marble2"} 
  And I wait "10" seconds

  #not yet implemented
  #creating marbles to test transferMarblesBasedOnColor

  #When a user invokes on the chaincode named "mycc" with args ["initMarble","marble100","red","5","cassey"]
  #And I wait "3" seconds

  #When a user invokes on the chaincode named "mycc" with args ["initMarble","marble101","blue","6","cassey"]
  #And I wait "3" seconds

  #When a user invokes on the chaincode named "mycc" with args ["initMarble","marble200","purple","5","ram"]
  #And I wait "3" seconds

  #When a user invokes on the chaincode named "mycc" with args ["initMarble","marble201","blue","6","ram"]
  #And I wait "3" seconds

  #When a user invokes on the chaincode named "mycc" with args ["transferMarblesBasedOnColor","blue","jerry"]
  #And I wait "3" seconds
  #When a user queries on the chaincode named "mycc" with args ["readMarble","marble100"]
  #Then a user receives a success response of {"docType":"marble","name":"marble100","color":"red","size":5,"owner":"cassey"}

  #When a user queries on the chaincode named "mycc" with args ["readMarble","marble101"]
  #Then a user receives a success response of {"docType":"marble","name":"marble101","color":"blue","size":6,"owner":"jerry"}

  #When a user queries on the chaincode named "mycc" with args ["readMarble","marble200"]
  #Then a user receives a success response of {"docType":"marble","name":"marble200","color":"purple","size":5,"owner":"ram"}

  #When a user queries on the chaincode named "mycc" with args ["readMarble","marble201"]
  #Then a user receives a success response of {"docType":"marble","name":"marble201","color":"blue","size":6,"owner":"jerry"}

  #  When a user invokes on the chaincode named "mycc" with args ["queryMarblesByOwner","ram"]
  #  And I wait "3" seconds
  #Then a user receives a success response of {"docType":"marble","name":"marble200","color":"purple","size":5,"owner":"ram"}


  Given the initial non-leader peer of "org1" is taken down

  When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble111","jerry"] on the initial leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"] on the initial leader peer of "org1"
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"jerry"} from the initial leader peer of "org1"
  And I wait "3" seconds
  When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble111","tom"] on the initial leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"] on the initial leader peer of "org1"
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"tom"} from the initial leader peer of "org1"

  Given the initial non-leader peer of "org1" comes back up

  And I wait "30" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"] on the initial non-leader peer of "org1"
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"tom"} from the initial non-leader peer of "org1"

  Examples:
    | type  | waitTime |
    | solo  |    20    |
    | kafka |    30    |

@skip
Scenario Outline: FAB-3511-2: Test chaincode fabric/examples/marbles02
  #includes tests for : initMarble, readMarble, deleteMarble, getHistoryForMarble, getMarblesByRange 
  Given I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user deploys chaincode at path "github.com/hyperledger/fabric-test/feature/chaincode/marbles02_private" with args [""] with name "mycc"
#  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/marbles02_private" with args [""] with name "mycc"
  And I wait "5" seconds
  Then the chaincode is deployed

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble1","red","35","tom"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble1"]
  Then a user receives a success response of {"docType":"marble","name":"marble1","color":"red","size":35,"owner":"tom"}

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble201","blue","6","ram"]
  And I wait "3" seconds
  # Test getHistoryForMarble
  When a user queries on the chaincode named "mycc" with args ["getHistoryForMarble","marble1"]
  And I wait "3" seconds
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble1","color":"red","size":35,"owner":"tom"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"false"

  #delete a marble
  When a user invokes on the chaincode named "mycc" with args ["delete","marble201"]
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble201"]
  Then a user receives an error response of status: 500
  And a user receives an error response of {"Error":"Marble does not exist: marble201"}
  And I wait "3" seconds


  #Test getHistoryForDeletedMarble
  When a user queries on the chaincode named "mycc" with args ["getHistoryForMarble","marble201"]
  And I wait "3" seconds
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble201","color":"blue","size":6,"owner":"ram"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"false"
  And I wait "3" seconds
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble201","color":"blue","size":6,"owner":"ram"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"true"

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble101","red","35","tom"]
  And I wait "3" seconds

  # Test getMarblesByRange
  When a user queries on the chaincode named "mycc" with args ["getMarblesByRange","marble1", "marble201"]
  And I wait "3" seconds
  Then a user receives a response containing {"Key":"marble1", "Record":{"docType":"marble","name":"marble1","color":"red","size":35,"owner":"tom"}}
  And a user receives a response containing {"Key":"marble101", "Record":{"docType":"marble","name":"marble101","color":"red","size":35,"owner":"tom"}}

  Examples:
    | type  | waitTime |
    | solo  |    20    |
    | kafka |    30    |
