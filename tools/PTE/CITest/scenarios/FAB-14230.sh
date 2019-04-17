#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# testcase: FAB-14230
# channels: 1
# org: 3
# thread: 54 (18 thread per org)
# tx 10,000 per thread (total 540,000 tx)
# traffic mode: Constant

#cd ~/gopath/src/github.com/hyperledger/fabric-test/tools/PTE/CITest/scenarios

# source PTE CI utils
source PTECIutils.sh

myTESTCASE="FAB-14230"
mySCDir="PTEScaleTest-SC"

myCC="samplecc"
myTXMODE="Constant"
myNORG=3

myNREQ=10000

myMinChan=1
myMaxChan=1
myChanIncr=1
myMinTh=18
myMaxTh=18
myThIncr=1
myFreq=0

myKey0=10000
myKeyIncr=$myNREQ

CWD=$PWD

# remove existing PTE report
CIpteReport=$LOGDir/$myTESTCASE"-pteReport.log"
echo "CIpteReport=$CIpteReport"

if [ -e $CIpteReport ]; then
    rm -f $CIpteReport
fi

# execute PTE
optString="--testcase $myTESTCASE --scdir $mySCDir -a $myCC --norg $myNORG --nreq $myNREQ --txmode $myTXMODE --freq $myFreq -i"
echo "[$myTESTCASE] optString=$optString"
PTEExecLoop $myMinChan $myMaxChan $myChanIncr $myMinTh $myMaxTh $myThIncr $myKey0 $myKeyIncr "${optString[@]}"
