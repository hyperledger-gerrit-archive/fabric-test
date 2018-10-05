The script, runTestPTE.sh, can be used to

* npm install fabric-client and fabric-ca-client
* generate connection profile of a given network and convert it to PTE service credential json
* install and instantiate chaincode
* execute PTE testcases:
    - full suite test: include 8 testcases
    - short suite test: include 2 test cases
    - user choice testcases


## Pre-requisites

* git clone fabric-test

    for example to git clone fabric-test release 1.1:
    - cd $GOPATH/src/github.com/hyperledger
    - git clone --single-branch -b release-1.1 https://github.com/hyperledger/fabric-test.git

* save network credential network.json in <cloud>/creds/network.json.  For example, for IBM cloud, it will be IBM/creds/network.json with the content similar to below for a case of 2 org:
   
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



## Assumptions:

* **channel**: one channel, namely **defaultchannel**
* **organization**: two organizations, namely **org1** and **org2**


## runTestPTE.sh:

    ./runTestPTE.sh -h
        USAGE:  ./runTestPTE.js [options] [values]

        -h, --help      View this help message

        --npm           npm install fabric-client packages
                        (Default: none)

        --cloud         targeted cloud [IBM]
                        (Default: none)

        --cprof         convert connection profile to PTE service credential json
                        (Default: none)

        -i, --install   install/instantiate chaincode
                        (Default: none)

        -t, --testcase  list of testcases
                        (available testcases: FAB-3808-2i, FAB-3811-2q, FAB-3807-4i, FAB-3835-4q, FAB-4038-2i, FAB-4036-2q, FAB-7329-4i, FAB-7333-4i

        -a, --all       install npm packages, convert connection profile, install/instantiate chaincode, and execute all testcases
                        (testcases include: FAB-3808-2i, FAB-3811-2q, FAB-3807-4i, FAB-3835-4q, FAB-4038-2i, FAB-4036-2q, FAB-7329-4i, FAB-7333-4i)

        examples:
        ./runTestPTE.sh --npm --cloud IBM --cprof -i -t FAB-3808-2i
        ./runTestPTE.sh --cloud IBM -t FAB-3808-2i FAB-3811-2q
        ./runTestPTE.sh --cloud IBM -a


## Test scenarios
#### full suite test: fullSantiy.sh

This command will execute full suite test including

- npm install
- generate network profile and convert it to PTE service credential json
- install/intantiate chaincodes
- execute all 8 testcases
- generate PTE report for each testcase

#### short suite test: shortSanity.sh

This command will execute a short suite test including

- npm install
- generate network profile and convert it to PTE service credential json
- install/intantiate chaincodes
- execute 2 testcases: FAB-3808-2i and FAB-3811-2q
- generate PTE report for each testcase

#### user choice

User can use the script, runTestPTE.sh, to execute any available testcases. For examples:

    ./runTestPTE.sh --npm --cloud IBM --cprof -i -t FAB-3808-2i
    ./runTestPTE.sh --cloud IBM -t FAB-7329-4i, FAB-7333-4i


## testcases

* FAB-3808-2i: samplecc, 2 threads X 10k invokes , filteredblock
* FAB-3811-2q: samplecc, 2 threads X 10k queries
* FAB-3807-4i: samplecc, 4 threads X 10k invokes , filteredblock
* FAB-3835-4q: samplecc, 4 threads X 10k queries
* FAB-4038-2i: samplejs, 2 threads X 10k invokes , filteredblock
* FAB-4036-2q: samplejs, 2 threads X 10k queries
* FAB-7329-4i: samplejs, 4 threads X 10k invokes, channel block
* FAB-7333-4i: samplejs, 4 threads X 10k invokes, filteredblock


## Test report

The test report is available in Logs/pteReport-<starting time of execution>.txt, such as pteReport-20181008160625.txt is the report for the test executed starts at 16:06:25 Oct. 8 2018.  The report includes all testcases in the test.
