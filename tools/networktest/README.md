# Hyperledger Fabric Distributed Network Testing

You have found the home for automated testing a fabric network in any topology.
Currently, we use [Performance Traffic Engine (PTE)](https://github.com/hyperledger/fabric-test/tree/release-1.1/tools/PTE)
as the client driver.
The script runPTE.sh invokes the PTE tool to execute a user-selected set of tests
using a connection profile provided as input by the user.
The connection profile may be based on the fabric deployment of choice (cloud offering, Cello, K8S or customized deployment).
For reference, a sample is provided in ./connectionprofile/.
The network topology must meet some basic minimum requirements, which are discussed in more detail below.
Here is a basic diagram depicting the flow.

![](overviewPTE.png)

## Introduction: PTE Network Test Driver
The PTE network test driver is designed to execute tests varying from
health checks and sanity tests to load, stress, and performance tests.
The runPTE.sh provides many valuable functions to ensure successful execution such as:

* npm install fabric-client and fabric-ca-client
* convert connection profiles to PTE service credential json
* install and instantiate chaincode
* execute selected PTE testcases

You can use the --help option in the script for more details.

Upon completion, testers can review the test report summary logs for each PTE test run
at `fabric-test/tools/networktest/Logs/pteReport*.log`


## Prerequisites

1. Install [Go](https://golang.org/doc/install).

1. Git-clone fabric-test repository, and go to the networktest directory

    For example, to set up fabric-test in release 1.1:

        cd $GOPATH/src/github.com/hyperledger
        git clone --single-branch -b release-1.1 https://github.com/hyperledger/fabric-test.git

        cd fabric-test/tools/networktest

1. Connection Profile

    The fully automated traffic scenario scripts that are available
    all assume a certain minimum network topology to be defined in the
    connection profile, and the network should be running already.
    The topology **MUST** include:

    * one channel, namely defaultchannel
    * two organizations, namely org1 and org2, as members of defaultchannel
    * a minimum of 1 peer in each org that has joined defaultchannel


## Examples to Execute Tests

   Run all tests available, using custom connection profile provided by user in the default location:

        ./runPTE.sh --cpdir mytopologydirectory -a

   Run a recommended sanity suite of two tests, using connection profile provided by user in the default location:

        ./runPTE.sh -t FAB-7329-4i FAB-7333-4i

