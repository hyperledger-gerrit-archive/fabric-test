#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# testcase: FAB-14350
# channels: 500
# org: 1
# thread: 500 threads (1 thread per channel)
# tx 10,000 per thread
# traffic mode: Constant

# source PTE CI utils
source PTECIutils.sh

myTESTCASE="FAB-14350"
mySCDir="PTEScaleTest-SC"

myCC="samplecc"
myTXMODE="Constant"
myNORG=1

myNREQ=1

myMinChan=35
myMaxChan=35
myChanIncr=1
myMinTh=1
myMaxTh=1
myThIncr=1

myKey0=0
myKeyIncr=$myNREQ

CWD=$PWD

# remove existing PTE report
CIpteReport=$LOGDir/$myTESTCASE"-pteReport.log"
echo "CIpteReport=$CIpteReport"

if [ -e $CIpteReport ]; then
    rm -f $CIpteReport
fi

# execute PTE
optString="--testcase $myTESTCASE --scdir $mySCDir -a $myCC --norg $myNORG --nreq $myNREQ --targetorderers UserDefined --txmode $myTXMODE -i"
echo "[$myTESTCASE] optString=$optString"
PTEExecLoop $myMinChan $myMaxChan $myChanIncr $myMinTh $myMaxTh $myThIncr $myKey0 $myKeyIncr "${optString[@]}"
