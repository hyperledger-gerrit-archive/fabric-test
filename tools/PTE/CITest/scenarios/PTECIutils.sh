#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

########## CI test utilits ##########

# common test directories
FabricTestDir=$GOPATH"/src/github.com/hyperledger/fabric-test"
NLDir=$FabricTestDir"/tools/NL"
PTEDir=$FabricTestDir"/tools/PTE"
CMDDir=$PTEDir"/CITest/scripts"
LOGDir=$PTEDir"/CITest/Logs"

# PTEReport()
# purpose: calcuate TPS and latency statistics from PTE generated report
# $1: input pteReport.txt generated from PTE
# $2: output pteReport.txt which the calcuated results will be appended
PTEReport () {

    if [ $# != 2 ]; then
       echo "[PTEReport] Error: invalid arguments number $# "
       exit 1;
    fi

    # save current working directory
    CurrWD=$PWD

    cd $CMDDir
    # calculate overall TPS and output report
    echo
    node get_pteReport.js $1
    cat $1 >> $2

    # restore working directory
    cd $CurrWD
}

