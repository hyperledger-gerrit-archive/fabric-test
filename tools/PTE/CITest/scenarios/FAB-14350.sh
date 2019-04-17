#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# Requirements:
# The script assumes that a network with 3 org and 1 peer per org  is operational, 500 channels are created and peers are joined, a chaincode
# is installed and instantiated.  The corresponding PTE service credential json is placed in a directory under PTE.  The default directory is
# PTEScaleTest-SC. If the user chooses not to use the default directory, then he needs to change mySCDir below to the name of the directory.

# testcase: FAB-14350: RAFT test with large number of channels
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
