
# Hyperledger Fabric Cloud Network Testing

You have found the home for test resources for cloud providers of Fabric.
All that is required is to produce a network connection profile, in order to leverage these automated tests and tools.
Currently we offer one test driver, and hope to offer more. Contributions are certainly welcome!

To make things even easier for network owners, we can also maintain additional supporting code that would
automatically create the connection profile of an existing network.
For example, we already have such content in the ./IBM directory designed to do that,
given the IBP Network ID, for IBP (IBM Blockchain Platform) Starter networks; and plans are
in the works for similar functionality for Enterprise networks.
Support for other networks may follow, for those cloud providers who can offer the public APIs needed.


  //////// ...we can create a PICTURE of this, with 3 or more clouds, 4 or more connProfiles...
  //////// ...each cloud can contain 4 items representing 2 orgs/4 peers...

  CLOUD                        INPUT                          EXECUTE                 OUTPUT

  cloud network (IBM Starter)  IBP_StarterID  --------------  sanity.sh or    ------  pteReport.log
                                                              runCloudPte.sh
                                                              or other driver
                                                              |   |   |
  cloud network (IBM Enterprise) ibm_connectionProfile  ------+   |   |
                                                                  |   |
  hybrid multi-cloud network   my_ConnectionProfile  -------------+   |
                                                                      |
  cloud network (Amazon AWS)   AWS_connectionProfile  ----------------+


## Introduction: Cloud PTE Test Driver
The cloud PTE test driver is designed to execute tests varying from health checks and sanity tests to load, stress, and performance tests.
There are some fully automated traffic scenario scripts that assume a certain minimum network topology.
Other scenarios may be added as desired.
We also have plans to offer an API for users to easily request their own customized test based on testing requirements.

The cloud PTE test driver is based on the Performance Traffic Engine (PTE)[link...]; it can be used to:

1 Run tests on any network in any supported cloud environment.
1 Select from a list of available traffic tests, using runCloudPte.sh.
1 Or choose to easily run a predefined sanity test suite, sanity.sh.

The script, runCloudPTE.sh, can be used to optionally do any or all of the following:

* npm install fabric-client and fabric-ca-client
* generate connection profile of a given network and convert it to PTE service credential json
* install and instantiate chaincode
* execute selected PTE testcases

Note: testers can review the test report summary logs after each PTE test run at `fabric-test/tools/PTE/CITest/Logs/pteReport.log`


### Prerequisites

#### Git-clone fabric-test repository, and go to the cloud directory

    ( provide a [link] to instructions to clone fabrictest and do any prereq installs of GO or Node, etc. _

    cd $GOPATH/src/github.com/hyperledger/fabric-test/testSuites/cloud/


#### Describe your network in a connection profile, network.json

Provide a connection profile, including your own network certs for all the organizations.
(Note: If you have an IBM Blockchain Platform Starter Plan network ID, we can automatically generate that for you!
We have yet to obtain API tools and methodology to automatically generate one for other host networks, but we hope to add more soon.)
Create a file named:

    .../fabric-test/testSuites/cloud/<cloudname>/creds/network.json

For example:

* For example, for an IBM cloud network, create file

    fabric-test/testSuites/cloud/IBM/creds/network.json

  which would contain content similar to the following for a network containing 2 organizations:

        {
            "org1": {
                "url": "https://blockchain-starter.ng.bluemix.net",
                "network_id": "nb9ccaf8ee68a4fc5a76de88bf52d63bb",
                "key": "org1",
                "secret": "<secret 1>"
            },
            "org2": {
                "url": "https://blockchain-starter.ng.bluemix.net",
                "network_id": "nb9ccaf8ee68a4fc5a76de88bf52d63bb",
                "key": "org2",
                "secret": "<secret 2>"
           }
        }


### Assumptions

To execute any of these tests, your network must contain

    * **channel**: one channel, namely **defaultchannel**
    * **organization**: two organizations, namely **org1** and **org2**
    * **chaincode**: the tests use the following supported chaincodes;
      choose runCloudPte.sh -i option, or
      install and instantiate them yourself before running the corresponding tests:

      For sanity.sh tests:
          full/path/to/samplecc

      For runCloudPte.sh -a option to run all tests:
          full/path/to/samplecc
          full/path/to/samplejs
          full/path/to/marbles02


### Execute tests

    ./sanity.sh
    ./sanity.sh -c <IBM|AWS>

    ./runTestPTE.sh -a

    ./runTestPTE.sh -h
       // Idea: Could we grep "Overall TEST RESULTS" from the pteReport file?
       // Should we do it after each testcase?
       // Should we enhance the script to return 0 if all passed and 1 if not?
       //    That way, the sanity.sh script could itself print and/or return a final result
       //    for the entire sanity test suite (which includes these pte tests and maybe more).


