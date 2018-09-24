#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

########## CI test ##########

removePteReport () {
  if [ -e $pteReport ]; then
    echo "remove $pteReport"
    rm -f $pteReport
  fi
}

calcTPS () {
# calculate overall TPS
echo ""
echo "node get_pteReport.js $1"
  node get_pteReport.js $1
cat $1 >> $2
}

CWD=$PWD
pteReport="../../pteReport.txt"

cd ../scripts

#### Launch network
./test_driver.sh -n -m FAB-11615-2iVal -p -c sbe_cc >& ../Logs/FAB-11615-precfg.log

#### first set of invokes
removePteReport
./test_driver.sh -t FAB-11615-2iVal
calcTPS $pteReport "../Logs/FAB-11615-2iEP-PTEReport-1.txt"

#### change EP
removePteReport
./test_driver.sh -t FAB-11615-2iEP
calcTPS $pteReport "../Logs/FAB-11615-2iEP-PTEReport-2.txt"

#### second set of invokes
removePteReport
./test_driver.sh -t FAB-11615-2iVal
calcTPS $pteReport "../Logs/FAB-11615-2iEP-PTEReport-3.txt"
