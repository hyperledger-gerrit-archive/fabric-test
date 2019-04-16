#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# purpose:
# to execute a PTE scenarios script on multiple remote systems

#printUsage ()
printUsage () {
    echo "Requirements:"
    echo "1. setup remote access, see https://github.com/hyperledger/fabric-test/blob/master/tools/PTE/README.md#remote-pte on how to setup remote access"
    echo "2. git clone farbic-test under $GOPATH/src/github.com/hyperledger/"
    echo "3. create a bash script in fabric-test/tools/PTE/CITest/scenarios"
    echo "4. update parameters in this script as needed:"
    echo "   4.1. define remote user ids, default=ibmadmin"
    echo "   4.2. define remote systems"
    echo "   4.3. add remote systems into RHOSTLIST below"
    echo
    echo "Usage:"
    echo "   ./runRemoteScenarios.sh <remote script>"
    echo
    echo "Example:"
    echo "   ./runRemoteScenarios.sh FAB-14230.sh"
    echo
}

if [ $# -eq 1 ]; then
    RTASK=$1
    echo "executing remote task: $RTASK ..."
else
    echo "Error: invalid input"
    printUsage
    exit
fi

#remote user id
remoteuser="ibmadmin"

# remote host IP
RHOST1=9.42.82.108      # remote host 1
RHOST2=9.37.134.110     # remote host 2
RHOST3=9.37.134.214     # remote host 3
RHOST10=9.42.18.129     # remote host 10
RHOST11=9.42.17.227     # remote host 11

RHOSTLIST=( $RHOST1 $RHOST2 $RHOST3 $RHOST10 )

#execute remote tasks
for remotehost in "${RHOSTLIST[@]}"
do
    echo "remotehost: $remotehost"
    ssh -l $remoteuser $remotehost /bin/bash << EOF
    if [ -e .nvm/nvm.sh ]; then
        source .nvm/nvm.sh
    fi
    node -v
    cd $GOPATH/src/github.com/hyperledger/fabric-test/tools/PTE/CITest/scenarios
    nohup ./$RTASK > nohup.log 2>&1 &
    exit

EOF

done

exit
