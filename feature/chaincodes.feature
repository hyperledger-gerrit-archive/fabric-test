#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: FAB-5384 Chaincode Testing: As a user I want to be able verify that I can execute different chaincodes


@daily
Scenario Outline: FAB-5797: Test chaincode fabric/examples/chaincode_example02 deploy, invoke, and query with chaincode install name in all lowercase/uppercase/mixedcase chars, for <type> orderer
    Given I have a bootstrapped fabric network of type <type>
    When a user sets up a channel
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "<ccName>"
    When a user queries on the chaincode named "<ccName>" with args ["query","a"]
    Then a user receives a success response of 1000
    When a user invokes on the chaincode named "<ccName>" with args ["invoke","a","b","10"]
    And I wait "3" seconds
    When a user queries on the chaincode named "<ccName>" with args ["query","a"]
    Then a user receives a success response of 990
Examples:
    | type  |   ccName   |
    | solo  |    mycc    |
    | solo  |    MYCC    |
    | solo  |  MYcc_Test |
    | kafka |    mycc    |
    | kafka |    MYCC    |
    | kafka |  MYcc_Test |

@daily
Scenario: FAB-4703: FAB-5663, Test chaincode calling chaincode - fabric/examples/chaincode_example04
  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example04" with args ["init","Event","1"] with name "myex04"
  When a user sets up a channel named "channel2"
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "myex02_a" on channel "channel2"
  When a user queries on the channel "channel2" using chaincode named "myex02_a" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the chaincode named "myex04" with args ["query","Event", "myex02_a", "a", "channel2"]
  Then a user receives a success response of 1000


@shimAPI
@daily
Scenario: FAB-4717: FAB-5663, chaincode-to-chaincode testing passing in channel name as a third argument to chaincode_ex05 when cc_05 and cc_02 are on different channels
  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example05" with args ["init","sum","0"] with name "myex05"
  When a user sets up a channel named "channel2"
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "myex02_b" on channel "channel2"
  When a user queries on the channel "channel2" using chaincode named "myex02_b" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the chaincode named "myex05" with args ["query","myex02_b", "sum", "channel2"]
  Then a user receives a success response of 3000


@daily
Scenario: FAB-4718: FAB-5663, chaincode-to-chaincode testing passing an empty string for channel_name when cc_05 and cc_02 are on the same channel
  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example05" with args ["init","sum","0"] with name "myex05"
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "myex02_b"
  When a user queries on the chaincode named "myex02_b" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the chaincode named "myex05" with args ["query","myex02_b", "sum", ""]
  Then a user receives a success response of 3000


# FAB-6677 : skip 4720,4721,4722 until FAB-6387 gets fixed so that we receive an error status code in addition to the error message
@skip
@daily
Scenario: FAB-4720: FAB-5663, Test chaincode calling chaincode -ve test case passing an incorrect or non-existing channnel name when cc_ex02 and cc_ex05 installed on same channels
  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example05" with args ["init","sum","0"] with name "myex05"
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "myex02_b"
  When a user queries on the chaincode named "myex02_b" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the chaincode named "myex05" with args ["query","myex02_b", "sum", "channel3"]
  Then a user receives an error response of status: 400


# FAB-6677 : skip 4720,4721,4722 until FAB-6387 gets fixed so that we receive an error status code in addition to the error message
@skip
@daily
Scenario: FAB-4721: FAB-5663, Test chaincode calling chaincode -ve testcase passing an incorrect ot non-existing string for channelname when cc_ex02 and cc_ex05 installed on different channels
  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example05" with args ["init","sum","0"] with name "myex05"
  When a user sets up a channel named "channel2"
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "myex02_b" on channel "channel2"
  When a user queries on the channel "channel2" using chaincode named "myex02_b" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the chaincode named "myex05" with args ["query","myex02_b", "sum", "channel3"]
  Then a user receives a success response of status: 400


# FAB-6677 : skip 4720,4721,4722 until FAB-6387 gets fixed so that we receive an error status code in addition to the error message
@skip
@daily
Scenario: FAB-4722: FAB-5663, Test chaincode calling chaincode -ve testcase passing an empty string for channelname when cc_ex02 and cc_ex05 installed on different channels
  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example05" with args ["init","sum","0"] with name "myex05"
  When a user sets up a channel named "channel2"
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "myex02_b" on channel "channel2"
  When a user queries on the channel "channel2" using chaincode named "myex02_b" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the chaincode named "myex05" with args ["query","myex02_b", "sum", ""]
  Then a user receives a success response of status: 400

@daily
Scenario: FAB-5384: FAB-5663, Test chaincode calling chaincode with two args cc_ex02 and cc_ex05 installed on same channels
  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example05" with args ["init","sum","0"] with name "myex05"
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "myex02_b"
  When a user queries on the chaincode named "myex02_b" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the chaincode named "myex05" with args ["query","myex02_b", "sum"]
  Then a user receives a success response of 3000


@daily
Scenario Outline: FAB-3888: State Transfer Test, bouncing a non-leader peer, using marbles02, for <type> orderer
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/marbles02" with args [""] with name "mycc"

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble1","red","35","tom"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble1"]
  Then a user receives a success response of {"docType":"marble","name":"marble1","color":"red","size":35,"owner":"tom"}

  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble111","pink","55","jane"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"]
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"jane"}

 When the initial non-leader peer of "org1" is taken down

  And a user invokes on the chaincode named "mycc" with args ["transferMarble","marble111","jerry"] on the initial leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"] on the initial leader peer of "org1"
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"jerry"} from the initial leader peer of "org1"
  And I wait "3" seconds
  When a user invokes on the chaincode named "mycc" with args ["transferMarble","marble111","tom"] on the initial leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"] on the initial leader peer of "org1"
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"tom"} from the initial leader peer of "org1"

  When the initial non-leader peer of "org1" comes back up

  And I wait "30" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble111"] on the initial non-leader peer of "org1"
  Then a user receives a success response of {"docType":"marble","name":"marble111","color":"pink","size":55,"owner":"tom"} from the initial non-leader peer of "org1"

  Examples:
    | type  |
    | solo  |
    | kafka |

@smoke
Scenario Outline: FAB-6211: Test example02 chaincode written using <language> <security>
    Given I have a bootstrapped fabric network of type solo <security>
    When a user sets up a channel
    And a user deploys chaincode at path "<path>" with args ["init","a","1000","b","2000"] with name "mycc" with language "<language>"
    When a user queries on the chaincode named "mycc" with args ["query","a"]
    Then a user receives a success response of 1000
    When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
    And I wait "3" seconds
    When a user queries on the chaincode named "mycc" with args ["query","a"]
    Then a user receives a success response of 990
    When a user queries on the chaincode named "mycc" with args ["query","b"]
    Then a user receives a success response of 2010
Examples:
    |                            path                                         | language | security    |
    | github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 | GOLANG   | with tls    |
    | github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 | GOLANG   | without tls |
    |        ../../fabric-test/chaincodes/example02/node                      | NODE     | with tls    |
    |        ../../fabric-test/chaincodes/example02/node                      | NODE     | without tls |


@shimAPI
@daily
Scenario Outline: FAB-6256: Test support of rich queries in SHIM API: queryMarbles and queryMarblesByOwner using marbles chaincode on couchdb 
    Given I have a bootstrapped fabric network of type solo using state-database couchdb with tls
    When a user sets up a channel
    And a user deploys chaincode at path "<path>" with args [""] with language "<language>"

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

    # queryMarbles on more than one selector
    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}","{\\"selector\\":{\\"color\\":\\"red\\"}}"]
    Then a user receives a response containing "Key":"marble2"
    And a user receives a response containing "name":"marble2"
    And a user receives a response containing "color":"red"
    And a user receives a response containing "owner":"tom"

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
    And a user receives a response containing "name":"marble2"
    And a user receives a response containing "color":"red"
    And a user receives a response containing "size":50
    And a user receives a response containing "owner":"jerry"

    When a user queries on the chaincode with args ["queryMarbles","{\\"selector\\":{\\"owner\\":\\"tom\\"}}"]
    Then a user receives a success response of []
Examples:
    |                             path                              | language |
    | github.com/hyperledger/fabric/examples/chaincode/go/marbles02 | GOLANG   |
    |        ../../fabric-test/chaincodes/marbles/node              | NODE     |

@daily
Scenario Outline: FAB-6439: Test chaincode enccc_example.go which uses encshim library extensions.
    #To generate good keys, we followed instructions as in the README.md under "github.com/hyperledger/fabric/examples/chaincode/go/enccc_example" folder
    # ENCKEY=`openssl rand 32 -base64`
    # IV=`openssl rand 16 -base64`
    # SIGKEY=`openssl ecparam -name prime256v1 -genkey | tail -n5 | base64 -w0`
    Given I have a bootstrapped fabric network of type <type>
    When a user sets up a channel
    And I vendor go packages for fabric-based chaincode at "../fabric/examples/chaincode/go/enccc_example"
    And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/enccc_example" with args ["init", ""] with name "mycc"
    And I locally execute the command "openssl rand 32 -base64" saving the results as "ENCKEY"
    And a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Social-Security-Number","123-45-6789"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
    And I wait "5" seconds
    When a user queries on the chaincode named "mycc" with args ["ENC","GET", "Social-Security-Number"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
    Then a user receives a success response of 123-45-6789
    When I locally execute the command "openssl rand 16 -base64" saving the results as "IV"
    When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Tax-Id","1234-012"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\",\\"IV\\":\\"{IV}\\"}"
    And I wait "5" seconds
    When a user queries on the chaincode named "mycc" with args ["ENC","GET","Tax-Id"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\",\\"IV\\":\\"{IV}\\"}"
    Then a user receives a response containing 1234-012
    When I locally execute the command "openssl ecparam -name prime256v1 -genkey | tail -n5 | base64 -w0" saving the results as "SIGKEY"
    When a user invokes on the chaincode named "mycc" with args ["SIG","PUT","Passport-Number","M9037"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\",\\"SIGKEY\\":\\"{SIGKEY}\\"}"
    And I wait "5" seconds
    When a user queries on the chaincode named "mycc" with args ["SIG","GET","Passport-Number"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\",\\"SIGKEY\\":\\"{SIGKEY}\\"}"
    Then a user receives a response containing M9037
    When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","WellsFargo-Savings-Account","09675879"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
    When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","BankOfAmerica-Savings-Account","08123456"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
    And I wait "3" seconds
    When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Employee-Number1","123-00-6789"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
    And I wait "3" seconds
    When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Employee-Number2","123-45-0089"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
    And I wait "3" seconds
    #for range use keys encrypted with 'ENC' 'PUT'
    When a user queries on the chaincode named "mycc" with args ["RANGE"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
    Then a user receives a response containing "key":"Employee-Number1"
    And a user receives a response containing "value":"123-00-6789"
    And a user receives a response containing "key":"Employee-Number2"
    And a user receives a response containing "value":"123-45-0089"
    And a user receives a response containing "key":"WellsFargo-Savings-Account"
    And a user receives a response containing "value":"09675879"
    And a user receives a response containing "key":"BankOfAmerica-Savings-Account"
    And a user receives a response containing "value":"08123456"

Examples:
    |  type  |
    |  solo  |
    | kafka  |


@daily
Scenario Outline: FAB-6650: Test chaincode enccc_example.go negative scenario, passing in bad ENCRYPTION(ENC), IV, and SIGNATURE(SIG) KEYS
  #To generate good keys, we followed instructions as in the README.md under "github.com/hyperledger/fabric/examples/chaincode/go/enccc_example" folder
  # ENCKEY=`openssl rand 32 -base64`
  # IV=`openssl rand 16 -base64`
  # SIGKEY=`openssl ecparam -name prime256v1 -genkey | tail -n5 | base64 -w0`
  # For the things we called BAD keys in this test,  we deleted last character from the generated good keys to corrupt them.

  Given I have a bootstrapped fabric network of type kafka
  When a user sets up a channel
  And I vendor go packages for fabric-based chaincode at "../fabric/examples/chaincode/go/enccc_example"
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/enccc_example" with args ["init", ""] with name "mycc"

  #first we test for invoke failures by passing in bad keys
  When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Social-Security-Number","123-45-6789"] and transient args "{\\"ENCKEY\\":\\"<BAD_ENC_KEY>\\"}"
  Then a user receives an error response of Error: Error parsing transient string: illegal base64 data at input byte 40 - <nil>
  When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Tax-Id","1234-012"] and transient args "{\\"ENCKEY\\":\\"<GOOD_ENC_KEY>\\",\\"IV\\":\\"<BAD_IV_KEY>\\"}"
  Then a user receives an error response of Error: Error parsing transient string: illegal base64 data at input byte 23 - <nil>
  When a user invokes on the chaincode named "mycc" with args ["SIG","PUT","Passport-Number","M9037"] and transient args "{\\"ENCKEY\\":\\"<GOOD_ENC_KEY>\\",\\"SIGKEY\\":\\"<BAD_SIG_KEY>\\"}"
  Then a user receives an error response of Error: Error parsing transient string: illegal base64 data at input byte 300 - <nil>

  #here we make sure invokes pass but test for query failures by passing in bad keys
  When I locally execute the command "openssl rand 32 -base64" saving the results as "ENCKEY"
  When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Employee-Number1","123-00-6789"] and generated transient args "{\\"ENCKEY\\":\\"{ENCKEY}\\"}"
  And I wait "5" seconds
  #query an encrypted entity without passing Encryption key
  When a user queries on the chaincode named "mycc" with args ["ENC","GET", "Social-Security-Number"]
  Then a user receives an error response of status: 500
  And a user receives an error response of Expected transient key ENCKEY
  #query passing in bad_enc_key
  When a user invokes on the chaincode named "mycc" with args ["ENC","PUT","Social-Security-Number","123-45-6789"] and transient args "{\\"ENCKEY\\":\\"<GOOD_ENC_KEY>\\"}"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["ENC","GET", "Social-Security-Number"] and generated transient args "{\\"ENCKEY\\":\\"<BAD_ENC_KEY>\\"}"
  Then a user receives an error response of Error: Error parsing transient string: illegal base64 data at input byte 40 - <nil>

Examples:
    |                   GOOD_ENC_KEY                         |                BAD_ENC_KEY                            |     BAD_IV_KEY              | BAD_SIG_KEY    |
    |   L6P9jLWR6d6E1KdGJBsUpzEm5QS6uVlS4onsteB+KaQ=         |    L6P9jLWR6d6E1KdGJBsUpzEm5QS6uVlS4onsteB+KaQ        |    +4DANc5uYLTnsH6Yy7v32g=  |  LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSUhYRkd1eWxyTlQ1WUdtd1E0MVBWeTJqVlZrcXhMMTdBN1pSM0lDL1RGakJvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFVHdWSEhrbklmUnUyZ3YwWU50R210akpDSHJzdThhekZ1OWZvUy9raUlPN2Q2aWhTWWRjdgpHbEoyNlF0WmtTTlhWNkJDLy91Z25ycGN3bldTdERsc1lRPT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo                                                                                                                         |


@shimAPI
@smoke
Scenario Outline: FAB-5791: Test API in SHIM interface using marbles02 and shimApiDriver chaincodes
# |  shim API in fabric/core/shim/chaincode.go	|   Covered in marbles02  chaincode                     |
# |        for chaincode invocation
# |        Init	                                |                init                                   |
# |        Invoke	                        |               invoke                                  |
# |        GetState 	                        | readMarble, initMarble, transferMarble                |
# |        PutState 	                        |    initMarble, transferMarble                         |
# |        DelState 	                        |             deleteMarble                              |
# |        CreateCompositeKey 	                |       initMarble, deleteMarble                        |
# |        SplitCompositeKey 	                |         transferMarblesBasedOnColor                   |
# |        GetStateByRange 	                |         transferMarblesBasedOnColor                   |
# |        GetQueryResult 	                | FAB-6256 readMarbles,queryMarbles,queryMarblesByOwner |
# |        GetHistoryForKey 	                |       getHistoryForMarble                             |
# | GetStatePartialCompositeKeyQuery	        |       transferMarblesBasedOnColor                     |

# |                                             |      Covered in shimApiDriver chaincode
# |        GetArgs                              |              getArgs                                  |
# |        GetArgsSlice                         |              getArgsSlice                             |
# |        GetStringArgs                        |              getStringArgs                            |
# |        GetFunctionAndParameters             |              getFunctionAndParameters                 |

# |        GetBinding                           |              getBinding                               |
# |        GetCreator                           |              getCreator                               |
# |        GetTxTimeStamp                       |              getTxTimeStamp                           |
# |        GetSignedProposal                    |              getSignedProposal                        |
# |        GetTransient                         |              getTransient                             |
# |        GetTxID                              |                                                       |
# |        GetDecorations                       |                                                       |
# |        SetEvent                             |                                                       |

# |        InvokeChaincode                      |           FAB-4717  ch_ex05 calling ch_ex02           |

  Given I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  And I vendor go packages for fabric-based chaincode at "../chaincodes/shimApiDriver/go/"
  When a user deploys chaincode at path "<marbles02Path>" with args [""] with name "mycc" with language "<language>"
  When a user deploys chaincode at path "<shimAPIDriverPath>" with args [""] with name "myShimAPI" with language "<language>"


  #first two marbles are used for getMarblesByRange
  When a user invokes on the chaincode named "mycc" with args ["initMarble","001m1","indigo","35","saleem"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","004m4","green","35","dire straits"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble1","red","35","tom"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble2","blue","55","jerry"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble111","pink","55","jane"]
  And I wait "5" seconds

  When a user queries on the chaincode named "mycc" with args ["readMarble","marble1"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble1"
  And a user receives a response containing "color":"red"
  And a user receives a response containing "size":35
  And a user receives a response containing "owner":"tom"


  When a user queries on the chaincode named "mycc" with args ["readMarble","marble2"]
  Then a user receives a response containing "docType":"marble"
  And a user receives a response containing "name":"marble2"
  And a user receives a response containing "color":"blue"
  And a user receives a response containing "size":55
  And a user receives a response containing "owner":"jerry"

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

# Begin creating marbles to to test transferMarblesBasedOnColor
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble100","red","5","cassey"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble101","blue","6","cassey"]
  When a user invokes on the chaincode named "mycc" with args ["initMarble","marble200","purple","5","ram"]
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
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble1","color":"red","size":35,"owner":"tom"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"false"

  #delete a marble
  When a user invokes on the chaincode named "mycc" with args ["delete","marble201"]
  And I wait "3" seconds
  When a user queries on the chaincode named "mycc" with args ["readMarble","marble201"]
  Then a user receives an error response of status: 500
  And a user receives an error response of {"Error":"Marble does not exist: marble201"}


  #Test getHistoryForDeletedMarble
  When a user queries on the chaincode named "mycc" with args ["getHistoryForMarble","marble201"]
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble201","color":"blue","size":6,"owner":"ram"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"false"
  Then a user receives a response containing "TxId"
  And a user receives a response containing "Value":{"docType":"marble","name":"marble201","color":"blue","size":6,"owner":"ram"}
  And a user receives a response containing "Timestamp"
  And a user receives a response containing "IsDelete":"true"

  When a user queries on the chaincode named "myShimAPI" with args ["getTxTimeStamp"]
  When a user queries on the chaincode named "myShimAPI" with args ["getCreator"]
  When a user invokes on the chaincode named "myShimAPI" with args ["testTxBinding"]
  When a user queries on the chaincode named "myShimAPI" with args ["getSignedProposal"]
  When a user queries on the chaincode named "myShimAPI" with args ["getTransient"]


  Examples:
   | type  | database | waitTime |                      marbles02Path                                            |         shimAPIDriverPath                                         | language|
   | solo  |  leveldb |   20     | github.com/hyperledger/fabric/examples/chaincode/go/marbles02                 |   github.com/hyperledger/fabric-test/chaincodes/shimApiDriver/go  | GOLANG  |
   | kafka |  couchdb |   30     | github.com/hyperledger/fabric/examples/chaincode/go/marbles02                 |   github.com/hyperledger/fabric-test/chaincodes/shimApiDriver/go  | GOLANG  |
#   | solo  |  leveldb |   20     | ../../fabrici-test/chaincodes/marbles/node                                    |   github.com/hyperledger/fabric-test/chaincodes/shimApiDriver/node| NODE    |
#   | kafka |  couchdb |   30     |  ../../fabric-test/chaincodes/marbles/node                                    |   github.com/hyperledger/fabric-test/chaincodes/shimApiDriver/node| NODE    |
# skip parts 3 & 4 using node chaincodes, until FAB-6271 gets fixed and we receive an an error code in addition to the error message:
