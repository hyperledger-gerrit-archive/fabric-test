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
Scenario: FAB-13958: Test new chaincode lifecycle - upgrade from old to new
  Given I have a bootstrapped fabric network of type solo
  When an admin sets up a channel
  And an admin deploys chaincode with args ["init","a","1000","b","2000"]
  And I wait up to "10" seconds for instantiation to complete
  When a user invokes on the chaincode with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode with args ["query","a"]
  Then a user receives a success response of 990

  # Upgrade the channel!!!
  Given I want to use the new chaincode lifecycle
  When an admin updates the "Application" capabilities in the channel config to version "V2_0"
  When all organization admins sign the updated channel config
  When the admin updates the channel using peer "peer0.org1.example.com"
  When an admin fetches genesis information using peer "peer0.org1.example.com"
  Then the config block file is fetched from peer "peer0.org1.example.com"
  Then the updated config block contains V2_0

  When an admin packages chaincode at path "github.com/hyperledger/fabric-test/chaincodes/example02/go/cmd" as version "2" with name "mycc2"
  And the organization admins install the chaincode package on all peers
  Then a hash value is received on all peers
  When each organization admin approves the chaincode package with policy "OR ('org1.example.com.member','org2.example.com.member')"
  And an admin commits the chaincode package to the channel
  And I wait up to "10" seconds for the chaincode to be committed
  And a user invokes on the chaincode named "mycc2" with args ["init","a","1000","b","2000"] on both orgs
  When a user queries on the chaincode named "mycc2" with args ["query","a"]
  Then a user receives a success response of 1000
  When a user invokes on the chaincode named "mycc2" with args ["invoke","a","b","10"]
  And I wait "5" seconds
  When a user queries on the chaincode named "mycc2" with args ["query","a"]
  Then a user receives a success response of 990


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
