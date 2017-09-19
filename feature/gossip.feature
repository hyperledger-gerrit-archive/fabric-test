# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Gossip Service
    As a user I expect the gossip component work correctly

@daily
Scenario Outline: [FAB-4663] [FAB-4664] [FAB-4665] A non-leader peer goes down by <takeDownType>, comes back up and catches up eventually
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "10" seconds
  Then the chaincode is deployed
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 990

  When the initial non-leader peer of "org1" is taken down by doing a <takeDownType>
  And I wait "5" seconds
  ## Now do 3 invoke-queries in leader peer
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 980 from the initial leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on the initial leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 960 from the initial leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on the initial leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 930 from the initial leader peer of "org1"

  When the initial non-leader peer of "org1" comes back up by doing a <bringUpType>
  And I wait "20" seconds

  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 930 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","40"] on the initial non-leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 890 from the initial leader peer of "org1"

  Examples:
    | type  | waitTime | takeDownType | bringUpType |
    | solo  |    5     |  stop        | start       |
    | solo  |    5     |  pause       | unpause     |
    | solo  |    5     | disconnect   | connect     |
    | kafka |    60    |  stop        | start       |
    | kafka |    60    |  pause       | unpause     |
    | kafka |    60    | disconnect   | connect     |

@daily
Scenario Outline: [FAB-4667] [FAB-4671] [FAB-4672] A leader peer goes down by <takeDownType>, comes back up *after* another leader is elected, catches up
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "10" seconds
  Then the chaincode is deployed

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 990 from the initial leader peer of "org1"

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 980 from the initial non-leader peer of "org1"

  When the initial leader peer of "org1" is taken down by doing a <takeDownType>
  # Give time to leader change to happen
  And I wait "30" seconds
  Then the initial non-leader peer of "org1" has become the leader
  ## Now do 3 invoke-queries
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 970 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on the initial non-leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 950 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on the initial non-leader peer of "org1"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 920 from the initial non-leader peer of "org1"

  When the initial leader peer of "org1" comes back up by doing a <bringUpType>
  And I wait "20" seconds

  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 920 from the initial leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","40"] on the initial leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 880 from the initial leader peer of "org1"

  Examples:
    | type  | waitTime | takeDownType | bringUpType |
    | solo  |    5     |  stop        | start       |
    | solo  |    5     |  pause       | unpause     |
    | solo  |    5     | disconnect   | connect     |
    | kafka |    60    |  stop        | start       |
    | kafka |    60    |  pause       | unpause     |
    | kafka |    60    | disconnect   | connect     |

@daily
Scenario Outline: FAB-4676] [FAB-4677] [FAB-4678] all the peers of an organization goes down temporarily by <takeDownType>, catches up 
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user sets up a channel
  And a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "10" seconds
  Then the chaincode is deployed

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 990 from the initial leader peer of "org1"

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 980 from the initial non-leader peer of "org1"

  ## take down leader, invoke in non-leader, wait 5 seconds and bring back up the initial leader
  When the initial leader peer of "org1" is taken down by doing a <takeDownType>
  And I wait "1" seconds
  And a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait " 5" seconds
  Then the initial non-leader peer of "org1" has not become the leader
  When the initial leader peer of "org1" comes back up by doing a <bringUpType>
  And I wait "20" seconds

  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 970 from the initial leader peer of "org1"
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 990

  #take down both peers in "org1"
  When "peer0.org1.example.com" is taken down by doing a <takeDownType>
  And I wait "5" seconds
  When "peer1.org1.example.com" is taken down by doing a <takeDownType>
  And I wait "5" seconds
  ## Now do 3 invoke-queries in leader peer from org2
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial leader peer of "org2"
  And I wait "5" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org2"
  Then a user receives a success response of 980 from the initial leader peer of "org2"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on the initial leader peer of "org2"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org2"
  Then a user receives a success response of 960 from the initial leader peer of "org2"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on the initial leader peer of "org2"
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org2"
  Then a user receives a success response of 930 from the initial leader peer of "org2"

  When "peer0.org1.example.com" comes back up by doing a <bringUpType>
  And I wait "20" seconds
  When "peer1.org1.example.com" comes back up by doing a <bringUpType>
  And I wait "20" seconds

  When a user queries on the chaincode named "mycc" with args ["query","a"] on "peer0.org1.example.com"
  Then a user receives a success response of 930 from "peer0.org1.example.com"
  When a user queries on the chaincode named "mycc" with args ["query","a"] on "peer1.org1.example.com"
  Then a user receives a success response of 930 from "peer1.org1.example.com"

  Examples:
    | type  | waitTime | takeDownType | bringUpType |
    | solo  |    5     |  stop        | start       |
    | solo  |    5     |  pause       | unpause     |
    | solo  |    5     | disconnect   | connect     |
    | kafka |    60    |  stop        | start       |
    | kafka |    60    |  pause       | unpause     |
    | kafka |    60    | disconnect   | connect     |
