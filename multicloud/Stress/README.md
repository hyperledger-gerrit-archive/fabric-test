
## Pre-requisites

git clone fabric-test release 1.1

* cd $GOPATH/src/github.com/hyperledger
* git clone --single-branch -b release-1.1 https://github.com/hyperledger/fabric-test.git


git clone ibp_sync_certs

* cd fabric-test/tools/PTE
* git clone https://github.com/asararatnakar/ibp_sync_certs.git


## Two ways to execute transactions on multi-cloud network:

* pte_multiCloud.sh: support existing CI testcases
* gen_cfgInputs.sh: customized testcases


## pte_multiCloud.sh

### Assumptions:

    **channel**: one channel, namely **defaultchannel**, is supported now
    **organization**: two organizations, namely **org1** and **org2**, are supported now
    **chaincode**: supported chaincodes are
          **samplecc*
          **samplejs**
          **marbles02**

### Steps to run pte_multiCloud.sh:

    ./pte_multiCloud.sh -h

    -h, --help      View this help message
    --npm       npm install fabric-client packages
                (Default: none)
    --cprof         directory of connection profile relative to cprof-convert
                (Default: none)
    -a, --all       install npm packages, convert connection profile, install/instantiate chaincode, and execute all testcases
                (testcases include: FAB-3808-2i, FAB-3811-2q, FAB-3807-4i, FAB-3835-4q, FAB-4038-2i, FAB-4036-2q, FAB-7329-4i, FAB-7333-4i
    -i, --install   install/instantiate chaincode
                (Default: none)
    -t, --testcase  list of testcases
                (available testcases: FAB-3807-4i, FAB-3808-2i, FAB-3811-2q, FAB-3835-4q, FAB-4036-2q, FAB-4038-2i, FAB-7329-4i, FAB-7331-4i


## gen_cfgInputs.sh
### Step to run gen_cfgInputs.sh

    ./gen_cfgInputs.sh -h

    -h, --help      View this help message
    -n, --name      list of channel
                    (Default: defaultchannel)
    -c, --channel   create/join channel
                    (Default: No)
    -o, --org       list of organizations
                    (Default: None)
    --norg          number of organization
                    (Default: 0)
    -i, --install   install/instantiate chaincode
                    (Default: No)
    -a, --app       list of chaincode
                    (Default: None)
    -d, --scdir     service credential files directory
                    (Default: None. This parameter is required.)
    -p, --prime     execute query to sych-up ledger, [YES|NO]
                    (Default: No)
    --txmode        transaction mode, [Constant|Mix|Burst]
                    (Default: Constant)
    -t, --tx        transaction type, [MOVE|QUERY]
                    (Default: None)
    --nproc         number of proc per org [integer]
                    (Default: 1)
    --nreq          number of transactions [integer]
                    (Default: 1000)
    --freq          transaction frequency [unit: ms]
                    (Default: 0)
    --rundur        duration of execution [integer]
                    (Default: 0)
    --keystart      transaction starting key [integer]
                    (Default: 0)

