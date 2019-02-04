#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# testcase: FAB-13810
# channels: 1
# org: 1
# threads: 1 (1 per org)
# tx duration: 3 days
# traffic mode: Constant
# frequency: 10 per second per thread

# source PTE CI utils
source PTECIutils.sh

myTESTCASE="PTEScaleTest"
myLog="FAB-13810"

myCC="samplecc"
myTXMODE="Constant"

myRundur=259200
myNREQ=0
myFREQ=100

myNORG=1
myMinChan=1
myMaxChan=1
myChanIncr=1
myMinTh=1
myMaxTh=1
myThIncr=1

myKey0=0
myKeyIncr=0

CWD=$PWD

CIpteReport=$LOGDir/$myTESTCASE"-pteReport.log"
echo "CIpteReport=$CIpteReport"

if [ -e $CIpteReport ]; then
    rm -f $CIpteReport
fi

# execute PTE
optString="-a $myCC --norg $myNORG --nreq $myNREQ --rundur $myRundur --freq $myFREQ --keystart $myKey0 --txmode $myTXMODE -i"
echo "[FAB-13810.sh] optString=$optString"
PTEExecLoop $myMinChan $myMaxChan $myChanIncr $myMinTh $myMaxTh $myThIncr $myKeyIncr "${optString[@]}"

mv $CIpteReport $LOGDir/$myLog"-pteReport.log"

exit 0
