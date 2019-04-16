#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# purpose:
# to fetch PTE report from remote systems and calculate overall test result

#    Requirements:
#    1. setup remote access, see https://github.com/hyperledger/fabric-test/blob/master/tools/PTE/README.md#remote-pte on how to setup remote access
#    2. update parameters in this script as needed:
#       2.1. define remote user id, default=ibmadmin
#       2.2. add/subtract remote systems in RHOSTLIST
#    3. result is in pteReport.txt in current directory
#
#    Usage:
#       ./runRemotePTEReport.sh
#


RCWD=$PWD/../..
echo "RCWD=$RCWD"
RFILE="pteReport.txt"
LFILE="pteReport.txt"
if [ -e $LFILE ]; then
   rm -f $LFILE
fi

# remote system list
RHOST1=9.42.82.108      # remote system 1
RHOST2=9.37.134.110     # remote system 2
RHOST3=9.37.134.214     # remote system 3
RHOST10=9.42.18.129     # remote system 10
RHOST11=9.42.17.227     # remote system 11

RHOSTLIST=( $RHOST1 $RHOST2 $RHOST3 $RHOST10 )

#execute remote jobs
echo "fething remote pte report txt ..."
set -x
for remotehost in "${RHOSTLIST[@]}"
do
    rsh $remotehost cat $RCWD/$RFILE >> $LFILE
done

echo "executing get_pteReport ..."
node ../scripts/get_pteReport.js pteReport.txt

set +x
exit
