Welcome to fabric-test
-------
You are in the right place if you are interested in testing the Hyperledger Fabric and related repositories.

## Getting Started
Here are some recommended setup steps.

#### Clone the repositories
The `fabric-test` repository contains submodules of other Hyperledger Fabric projects that are used in testing.

The following repositories will need to be cloned separately with their corresponding images built.
* fabric
    * fabric-orderer
    * fabric-peer
    * fabric-kafka
    * fabric-zookeeper
    * fabric-tools
    * fabric-couchdb
    * fabric-testenv
* fabric-ca
    * fabric-ca


#### Update git submodules
The git submodules need to be initialized when the repository is first cloned. Use the following command.
```
  cd fabric-test
  git submodule update --init --recursive
```
**When making changes for committing to a submodule, make the change in the actual repository and not in the submodule. This makes managing changes much easier when working with submodules.**

When updating the git submodules with a more recent commit sha from the repository master, use the following command:
```
git submodule foreach git pull origin master
```

#### Get and build the latest code

```
  cd ../fabric-ca
  make docker

  cd ../fabric
  make docker configtxgen cryptogen

  # cello instructions coming soon  #WIP
```

## Tools Used to Execute Tests

#### Behave - functional and system tests
Please see the README located in the `feature` directory for more detailed information for using and contributing to the Fabric system behave framework.

The tests that utilize this framework cover atleast one of the following categories:
* basic functionality
* feature behaviors
* configuration settings - both network and component based
* negative testing
* upgrades and fallbacks
* chaincode API testing

The following are not covered in using this tool:
* scalability
* performance
* long running tests
* stress testing
* timed tests

# Continuous Integration

Above mentioned tests are now integrated in CI. Every patch set triggers a `fabric-test-verify` job and execute `behave smoke` tests. Once the build is successfully
execute, CI sends gerrit voting +1 back to corrsponding gerrit patch set otherwise it sends -1. Please see the below fabric-test CI job page

https://jenkins.hyperledger.org/view/fabric-test/

Jenkins also triggers CI daily job (https://jenkins.hyperledger.org/view/fabric-test/job/fabric-test-daily-x86_64/) to test tagged behave daily tests by cloning latest fabric and fabric-ca repo commits. Fabric-test daily job performs below steps

* Clone latest fabric and fabric-ca commits
* Build docker images and binary files
* Build peer, orderer, cryptogen and configtxgen
* Update git submodules and install all the python required modules in virtual env
* Run `behave daily` tests
* After the tests are completed, CI job generate test results and populate on Job console. Click here to view the Test Results
https://jenkins.hyperledger.org/view/fabric-test/job/fabric-test-daily-x86_64/test_results_analyzer/

#### NetworkLauncher - dynamically build a Fabric network
Please see the README located in the `tools/NL` directory for more detailed information for using the Networker Launcher to dynamically build a Fabric network.


.. Licensed under Creative Commons Attribution 4.0 International License
   https://creativecommons.org/licenses/by/4.0/
