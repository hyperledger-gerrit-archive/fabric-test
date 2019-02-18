# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


Feature: Lifecycle Service
    As a user I want to be able to the new chaincode lifecycle

@daily
Scenario: FAB-13701: Test new chaincode lifecycle - Basic workflow
  Given I changed the "Application" capability to version "V2_0"
  And I have a bootstrapped fabric network of type solo
  And I want to use the new chaincode lifecycle
  When an admin sets up a channel
  And an admin packages a chaincode
  And the organization admins install the chaincode package on all peers
  Then a hash value is received on all peers
  #When each organization admin approves the chaincode package
  When each organization admin approves the chaincode package with policy "OR ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel
  And I wait up to "10" seconds for the chaincode to be committed

  When a user invokes on the chaincode with args ["init","a","1000","b","2000"] on both orgs
  And I wait up to "30" seconds for deploy to complete
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 990


@daily
Scenario: FAB-13701a: Test new chaincode lifecycle - no policy set *************************FAILS
  Given I changed the "Application" capability to version "V2_0"
  And I have a bootstrapped fabric network of type solo
  And I want to use the new chaincode lifecycle
  When an admin sets up a channel
  And an admin packages a chaincode
  And the organization admins install the chaincode package on all peers
  Then a hash value is received on all peers
  When each organization admin approves the chaincode package
  And an admin commits the chaincode package to the channel
  And I wait up to "10" seconds for the chaincode to be committed
  And a user invokes on the chaincode with args ["init","a","1000","b","2000"] on both orgs
  And I wait up to "30" seconds for deploy to complete
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 990


#@doNotDecompose
@daily
Scenario: FAB-13701b: Test new chaincode lifecycle - upgrade both using new *************************FAILS
  Given I changed the "Application" capability to version "V2_0"
  And I have a bootstrapped fabric network of type solo
  And I want to use the new chaincode lifecycle
  When an admin sets up a channel

  And an admin packages a chaincode
  And the organization admins install the chaincode package on all peers
  Then a hash value is received on all peers

  When each organization admin approves the chaincode package with policy "OR ('org1.example.com.member','org2.example.com.member')"

  And an admin commits the chaincode package to the channel
  And I wait up to "10" seconds for the chaincode to be committed
  And a user invokes on the chaincode with args ["init","a","1000","b","2000"] on both orgs
  And I wait up to "30" seconds for deploy to complete

  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 1000

  #And I wait "5" seconds
  When an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/go/cmd" as version "2" with name "mycc2"
  And the organization admins install the chaincode package on all peers
  Then a hash value is received on all peers
  When each organization admin approves the upgraded chaincode package
  #When each organization admin approves the chaincode package with policy "AND ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel
  And a user invokes on the chaincode with args ["init","a","1000","b","2000"] on both orgs
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 1000

  #When an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/go/cmd" as version "17.0.1" with name "helloNurse" written in "GOLANG" using peer "peer0.org1.example.com"

@daily
Scenario: FAB-13983: Test new chaincode lifecycle - Chaincode calling chaincode
  Given I changed the "Application" capability to version "V2_0"
  And I have a bootstrapped fabric network of type solo
  And I want to use the new chaincode lifecycle

  When an admin sets up a channel named "channel2"
  And an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/go/cmd" with name "ex02"
  And the organization admins install the built "ex02" chaincode package on all peers
  Then a hash value is received on all peers
  #When each organization admin approves the "ex02" chaincode package on "channel2"
  When each organization admin approves the "ex02" chaincode package on "channel2" with policy "OR ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel "channel2"
  And I wait up to "10" seconds for the chaincode to be committed
  And a user invokes on the channel "channel2" using chaincode named "ex02" with args ["init","a","1000","b","2000"]
  And I wait up to "30" seconds for deploy to complete

  When an admin sets up a channel named "channel1"
  And an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example04/cmd" with name "ex04"
  And the organization admins install the built "ex04" chaincode package on all peers
  Then a hash value is received on all peers
  #When each organization admin approves the "ex04" chaincode package on "channel1"
  When each organization admin approves the "ex04" chaincode package on "channel1" with policy "OR ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel "channel1"
  And I wait up to "10" seconds for the chaincode to be committed
  And a user invokes on the channel "channel1" using chaincode named "ex04" with args ["init","Event","1"]
  And I wait up to "30" seconds for deploy to complete

  When a user queries on the channel "channel2" using chaincode named "ex02" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the channel "channel1" using chaincode named "ex04" with args ["query","Event","ex02","a","channel2"]
  Then a user receives a success response of 1000

  # Now upgrade chaincode on both channels
  When an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/go/cmd" as version "2" with name "ex02_2"
  And the organization admins install the built "ex02_2" chaincode package on all peers
  Then a hash value is received on all peers
  When each organization admin approves the "ex02_2" chaincode package on "channel2" with policy "AND ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel "channel2"
  And a user invokes on the channel "channel2" using chaincode named "ex02_2" with args ["init","a","1000","b","2000"]

  When an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example04/go/cmd" as version "2" with name "ex04_2"
  And the organization admins install the built "ex04_2" chaincode package on all peers
  Then a hash value is received on all peers
  When each organization admin approves the "ex04_2" chaincode package on "channel1" with policy "AND ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel "channel1"
  And a user invokes on the channel "channel1" using chaincode named "ex04_2" with args ["init","a","1000","b","2000"]

  When a user queries on the channel "channel2" using chaincode named "ex02_2" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user queries on the channel "channel1" using chaincode named "ex04_2" with args ["query","Event","ex02_2","a","channel2"]
  Then a user receives a success response of 1000



  #@doNotDecompose
@daily
Scenario: FAB-13971: Test adding new org using new chaincode lifecycle
  Given I changed the "Application" capability to version "V2_0"
  And I have a bootstrapped fabric network of type solo
  And I want to use the new chaincode lifecycle
  When an admin sets up a channel
  And an admin packages a chaincode
  And the organization admins install the chaincode package on all peers
  Then a hash value is received on all peers
  When each organization admin approves the chaincode package with policy "OR ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel
  And I wait up to "10" seconds for the chaincode to be committed

  When a user invokes on the chaincode with args ["init","a","1000","b","2000"] on both orgs
  And I wait up to "30" seconds for deploy to complete
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 990

  # Start update process
  When an admin adds an organization to the channel config
  # Assume channel config file is distributed out of band
  And all organization admins sign the updated channel config
  When the admin updates the channel using peer "peer0.org1.example.com"

  When an admin fetches genesis information using peer "peer0.org1.example.com"
  Then the config block file is fetched from peer "peer0.org1.example.com"
  Then the updated config block contains Org3ExampleCom

  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 980

  When the peers from the added organization are added to the network

  When an admin fetches genesis information at block 0 using peer "peer0.org3.example.com"
  When an admin makes peer "peer0.org3.example.com" join the channel
  And an admin makes peer "peer1.org3.example.com" join the channel

  When the organization admins install the chaincode package on peer "peer0.org3.example.com"
  Then a hash value is received on peer "peer0.org3.example.com"
  When the organization admins install the chaincode package on peer "peer1.org3.example.com"
  Then a hash value is received on peer "peer1.org3.example.com"

  #When each organization admin approves the upgraded chaincode package with policy "OR (AND ('org1.example.com.member','org2.example.com.member'), AND ('org1.example.com.member','org3.example.com.member'), AND ('org2.example.com.member','org3.example.com.member'))"
  When each organization admin approves the upgraded chaincode package with policy "OutOf(2,'org1.example.com.member','org2.example.com.member','org3.example.member')"

  And an admin commits the chaincode package to the channel on peer "peer0.org3.example.com"
  And I wait up to "10" seconds for the chaincode to be committed on peer "peer0.org3.example.com"
  And a user invokes on the chaincode with args ["init","a","1000","b","2000"] on "peer0.org3.example.com"
  And I wait up to "30" seconds for deploy to complete

  When a user queries on the chaincode with args ["query","a"] from "peer0.org3.example.com"
  Then a user receives a success response of 980 from "peer0.org3.example.com"

  When a user queries on the chaincode with args ["query","a"]
  #Then a user receives a success response of 1000
  Then a user receives a success response of 980
  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  #Then a user receives a success response of 990
  Then a user receives a success response of 970

  When a user queries on the chaincode with args ["query","a"] from "peer0.org3.example.com"
  Then a user receives a success response of 970 from "peer0.org3.example.com"

  ########################################################
  # Breaks  on invoke with the following error:
  # 2019-02-11 16:38:42.623 UTC [vscc] Validate -> ERRO 1ab VSCC error: stateBasedValidator.Validate failed, err validation of endorsement policy for chaincode mycc in tx 11:0 failed: signature set did not satisfy policy
  #  query return 970 because the invoke is unsuccessful
  When a user invokes on the chaincode with args ["invoke","a","b","10"] on "peer0.org3.example.com"
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 960

  # now remove an org
  When an admin fetches genesis information using peer "peer0.org1.example.com"
  Then the config block file is fetched from peer "peer0.org1.example.com"
  When an admin removes an organization named Org2ExampleCom from the channel config
  And all organization admins sign the updated channel config
  When the admin updates the channel using peer "peer0.org1.example.com"

  When an admin fetches genesis information using peer "peer0.org1.example.com"
  Then the config block file is fetched from peer "peer0.org1.example.com"
  Then the updated config block does not contain Org2ExampleCom

  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 950
  When a user queries on the chaincode with args ["query","a"] from "peer0.org2.example.com"
  Then a user receives a success response of 960 from "peer0.org2.example.com"


@daily
Scenario: FAB-13959: An admin from an org does not install chaincode package
  Given I changed the "Application" capability to version "V2_0"
  And I have a bootstrapped fabric network of type solo
  And I want to use the new chaincode lifecycle
  When an admin sets up a channel
  When an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/go/cmd" as version "2" with name "mycc2"
  And the organization admins install the built "mycc2" chaincode package on peer "peer0.org1.example.com"
  Then a hash value is received on peer "peer0.org1.example.com"
  When the organization admins install the built "mycc2" chaincode package on peer "peer1.org1.example.com"
  Then a hash value is received on peer "peer1.org1.example.com"
  # Note install does not take place on org2 peers
  When each organization admin approves the chaincode package with policy "OR ('org1.example.com.member','org2.example.com.member')"
  # Failed: peer lifecycle chaincode approveformyorg --name mycc2 --channelID behavesystest --version 2 --peerAddresses 192.168.240.6:7051 --peerAddresses 192.168.240.7:7051 --hash 730045c6268d8b4dc31800b0bee475b3c9776d59734f91ac8e130b03d4a025c5 --sequence 1 --init-required --waitForEvent --orderer orderer0.example.com:7050 --policy \\"OR (\'org1.example.com.member\',\'org2.example.com.member\')\\" "']: Error: error endorsing proposal: rpc error: code = Unknown desc = access denied: channel [behavesystest] creator org [org1.example.com]
  And an admin commits the chaincode package to the channel
  Then a user receives a response containing 'Error: could not assemble transaction: ProposalResponsePayloads do not match' from "peer0.org1.example.com"
  #  And I wait up to "10" seconds for the chaincode to be committed
  #  Then a user receives a response containing 'error endorsing proposal' from "peer0.org2.example.com"
  #  Then a user receives a response containing '<Error Message>' from "peer1.org2.example.com"


@daily
Scenario: FAB-13968: Upgrade chaincode for different orgs, but committing the chaincode definition with older version of chaincode
  Given I changed the "Application" capability to version "V2_0"
  And I have a bootstrapped fabric network of type solo
  And I want to use the new chaincode lifecycle
  When an admin sets up a channel
  And an admin packages a chaincode
  And the organization admins install the chaincode package on all peers
  Then a hash value is received on all peers
  #When each organization admin approves the chaincode package
  When each organization admin approves the chaincode package with policy "OR ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel
  And I wait up to "10" seconds for the chaincode to be committed

  And a user invokes on the chaincode with args ["init","a","1000","b","2000"]
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 1000

  When an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/go/cmd" as version "2" with name "mycc2"
  And the organization admins install the built "mycc2" chaincode package on all peers
  Then a hash value is received on all peers

  # Note the approval below is for the originally installed chaincode
  # Simulates the installation of an upgrade, but no one wants to use it
  #    at this time. 

  When each organization admin approves the version "0" upgraded chaincode package with policy "OR ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the version "0" chaincode package to the channel
  And a user invokes on the chaincode with args ["init","a","1000","b","2000"]
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 1000
