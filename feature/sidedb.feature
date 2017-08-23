# Copyright SecureKey Technologies Inc. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: FAB-1151 Side DB Testing: Side DB - Private Data Channel

Scenario: FAB-5080: Test chaincode API support for private data partitions
  # Requires Fabric commit 8a86221, and: https://gerrit.hyperledger.org/r/#/c/12257/, https://gerrit.hyperledger.org/r/#/c/12467/

  Given I have a bootstrapped fabric network of type solo
  And I wait "10" seconds
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/map" with args ["init"] with name "sidedbcc"
  And I wait "10" seconds
  Then the chaincode is deployed

  # PutPrivateData
  When a user invokes on the chaincode named "sidedbcc" with args ["putPrivate","col1","marble1","red"]
  When a user invokes on the chaincode named "sidedbcc" with args ["putPrivate","col1","marble2","blue"]
  When a user invokes on the chaincode named "sidedbcc" with args ["putPrivate","col2","marble1","yellow"]
  When a user invokes on the chaincode named "sidedbcc" with args ["putPrivate","col2","marble2","black"]
  When a user invokes on the chaincode named "sidedbcc" with args ["putPrivate","col2","marble3","green"]
  And I wait "15" seconds

  # GetPrivateData
  When a user queries on the chaincode named "sidedbcc" with args ["getPrivate","col1","marble1"]
  Then a user receives a success response of "red"
  When a user queries on the chaincode named "sidedbcc" with args ["getPrivate","col1","marble2"]
  Then a user receives a success response of "blue"
  When a user queries on the chaincode named "sidedbcc" with args ["getPrivate","col2","marble1"]
  Then a user receives a success response of "yellow"
  When a user queries on the chaincode named "sidedbcc" with args ["getPrivate","col2","marble2"]
  Then a user receives a success response of "black"
  When a user queries on the chaincode named "sidedbcc" with args ["getPrivate","col2","marble3"]
  Then a user receives a success response of "green"

  # GetPrivateDataByRange (Requires: https://gerrit.hyperledger.org/r/#/c/12671/)
  When a user queries on the chaincode named "sidedbcc" with args ["keysPrivate","col1","",""]
  Then a user receives a success response of ["marble1","marble2"]
  When a user queries on the chaincode named "sidedbcc" with args ["keysPrivate","col2","",""]
  Then a user receives a success response of ["marble1","marble2","marble3"]
  When a user queries on the chaincode named "sidedbcc" with args ["keysPrivate","col2","marble2",""]
  Then a user receives a success response of ["marble2","marble3"]

  # GetPrivateDataQueryResult (for CouchDB only)
  ## TODO

  # DelPrivateData
  When a user invokes on the chaincode named "sidedbcc" with args ["removePrivate","col1","marble1"]
  And I wait "5" seconds
  When a user queries on the chaincode named "sidedbcc" with args ["getPrivate","col1","marble1"]
  Then a user receives a success response of ""


Scenario: FAB-5085: Test endorsement fulfillment of private data policies (including append-only)
  ## TODO


Scenario: FAB-5092: Test ledger purge from private state db and write set storage based on block-to-live (BTL) policy
  ## TODO


Scenario: Ensure that the collection key/value hashes are correctly set on the public ledger
  ## TODO
