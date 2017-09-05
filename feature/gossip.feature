# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

Feature: Gossip Service
    As a user I expect the gossip component work correctly

@daily
Scenario Outline: [FAB-4663] [FAB-4664] [FAB-4665] A non-leader peer goes down by <takeDownType> temporarily, is expected to catch up and have all missing blocks eventually
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "5" seconds
  Then the chaincode is deployed
  When a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"]
  And a user queries on the chaincode named "mycc" with args ["query","a"]
  Then a user receives a success response of 990

  Given the initial non-leader peer of "org1" is taken down by doing a <takeDownType>
  And I wait "10" seconds
  ## Now do 5 invoke-queries in leader peer
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 980 from the initial leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on the initial leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 960 from the initial leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on the initial leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 930 from the initial leader peer of "org1"

  Given the initial non-leader peer of "org1" comes back up by doing a <bringUpType>
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

  @FAB4667
  @doNotDecompose
Scenario Outline: [FAB-4667] [FAB-4671] [FAB-4672] A leader peer goes down by <takeDownType> temporarily, comes back up *after* anoher leader is elected, is expected to catch up and have all missing blocks eventually
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "5" seconds
  Then the chaincode is deployed

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 990 from the initial leader peer of "org1"

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 980 from the initial non-leader peer of "org1"

  Given the initial leader peer of "org1" is taken down by doing a <takeDownType>
  # Give time to leader change to happen
  And I wait "30" seconds
  And the initial non-leader peer of "org1" has become the leader
  ## Now do 5 invoke-queries
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 970 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 950 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 920 from the initial non-leader peer of "org1"

  Given the initial leader peer of "org1" comes back up by doing a <bringUpType>
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
Scenario Outline: [FAB-4667] [FAB-4671] [FAB-4672] A leader peer goes down by <takeDownType> temporarily, comes back up *after* anoher leader is elected, is expected to catch up and have all missing blocks eventually
  Given the CORE_LOGGING_GOSSIP environment variable is "DEBUG"
  And I have a bootstrapped fabric network of type <type>
  And I wait "<waitTime>" seconds
  When a user deploys chaincode at path "github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02" with args ["init","a","1000","b","2000"] with name "mycc"
  And I wait "5" seconds
  Then the chaincode is deployed

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial leader peer of "org1"
  Then a user receives a success response of 990 from the initial leader peer of "org1"

  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 980 from the initial non-leader peer of "org1"

  Given the initial leader peer of "org1" is taken down by doing a <takeDownType>
  And I wait "90" seconds
  And the initial non-leader peer of "org1" has become the leader
  ## Now do 5 invoke-queries in the nonleader peer
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","10"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  And a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 970 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","20"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 950 from the initial non-leader peer of "org1"
  When a user invokes on the chaincode named "mycc" with args ["invoke","a","b","30"] on the initial non-leader peer of "org1"
  And I wait "10" seconds
  When a user queries on the chaincode named "mycc" with args ["query","a"] on the initial non-leader peer of "org1"
  Then a user receives a success response of 920 from the initial non-leader peer of "org1"

  Given the initial leader peer of "org1" comes back up by doing a <bringUpType>
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
