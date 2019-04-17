#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# testcase: FAB-14922
# channels: 1
# org: 1
# thread: 1
# tx: 1
# traffic mode: Constant

# source PTE CI utils
source PTECIutils.sh

myTESTCASE="FAB-14922"
mySCDir="PTEScaleTest-SC"

myCC="samplecc"
myTXMODE="Constant"
myNORG=1

myNREQ=1

chan0=1
myMinChan=1
myMaxChan=1
myChanIncr=1
myMinTh=1
myMaxTh=1
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
optString="--testcase $myTESTCASE --scdir $mySCDir -a $myCC --chan0 $chan0 --norg $myNORG --nreq $myNREQ --txmode $myTXMODE --freq $myFreq -i"
echo "[$myTESTCASE] optString=$optString"
PTEExecLoop $myMinChan $myMaxChan $myChanIncr $myMinTh $myMaxTh $myThIncr $myKey0 $myKeyIncr "${optString[@]}"
