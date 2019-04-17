#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# testcase: FAB-14269
# vLaunch: 3
# channels: 1
# org: 3
# thread: 54 (18 thread per org per vLaunch)
# tx 10,000 per thread (total 540,000 tx)
# traffic mode: Constant

#cd ~/gopath/src/github.com/hyperledger/fabric-test/tools/PTE/CITest/scenarios

# source PTE CI utils
source PTECIutils.sh

myTESTCASE="FAB-14269"
mySCDir="PTEScaleTest-SC"

myCC="samplecc"
myTXMODE="Constant"
myNORG=2

myNREQ=10000

chan0=1
myMinChan=9
myMaxChan=9
myChanIncr=1
myMinTh=1
myMaxTh=1
myThIncr=1
myFreq=810

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
optString="--testcase $myTESTCASE --scdir $mySCDir -a $myCC --chan0 $chan0 --norg $myNORG --nreq $myNREQ --txmode $myTXMODE --freq $myFreq -i"
echo "[$myTESTCASE] optString=$optString"
PTEExecLoop $myMinChan $myMaxChan $myChanIncr $myMinTh $myMaxTh $myThIncr $myKey0 $myKeyIncr "${optString[@]}"
