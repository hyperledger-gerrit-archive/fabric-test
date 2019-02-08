#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# testcase: FAB-13892
# channels: 1...100
# org: 3
# thread: 3*n (3 per channel), n=number of channel
# tx 10,000 per thread
# traffic mode: Constant

# source PTE CI utils
source PTECIutils.sh

myTESTCASE="PTEScaleTest"
myLog="FAB-13892"

myCC="samplecc"
myTXMODE="Constant"
myNORG=3

myNREQ=10000

myMinChan=1
myMaxChan=10
myChanIncr=1
myMinTh=1
myMaxTh=2
myThIncr=1

myKey0=0
myKeyIncr=$myNREQ

CWD=$PWD

CIpteReport=$LOGDir/$myTESTCASE"-pteReport.log"
echo "CIpteReport=$CIpteReport"

if [ -e $CIpteReport ]; then
    rm -f $CIpteReport
fi

# execute PTE
optString="-a $myCC --norg $myNORG --nreq $myNREQ --keystart $myKey0 --txmode $myTXMODE -i"
echo "[FAB-13892.sh] optString=$optString"
PTEExecLoop $myMinChan $myMaxChan $myChanIncr $myMinTh $myMaxTh $myThIncr $myKeyIncr "${optString[@]}"

mv $CIpteReport $LOGDir/$myLog"-pteReport.log"

exit 0
