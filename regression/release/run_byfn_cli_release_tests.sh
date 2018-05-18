#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# RUN BYFN tests on latest release images and binaries
######################################################

rm -rf ${GOPATH}/src/github.com/hyperledger/fabric-samples

WD="${GOPATH}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD

#curl -L https://raw.githubusercontent.com/hyperledger/fabric/${GERRIT_BRANCH}/Makefile > Makefile
#RELEASE_VERSION=$(cat Makefile | grep "BASE_VERSION =" | awk '{print $3}')
echo "--------> RELEASE_VERSION : $RELEASE_VERSION"

curl -sSL https://goo.gl/6wtTN5 | bash -s $RELEASE_VERSION

# Delete temporary Makefile.
# rm -rf Makefile

cd $WD/first-network || exit
export PATH=$WD/bin:$PATH

echo "############## BYFN,EYFN DEFAULT CHANNEL TEST#############"
echo "#########################################################"
echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
echo y | ./byfn.sh -m up -t 60
echo y | ./eyfn.sh -m up
echo y | ./eyfn.sh -m down
echo
echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
echo "#########################################################"

echo y | ./byfn.sh -m generate -c fabricrelease
echo y | ./byfn.sh -m up -c fabricrelease -t 60
echo y | ./eyfn.sh -m up -c fabricrelease -t 60
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN COUCHDB TEST #############"
echo "####################################################"

echo y | ./byfn.sh -m generate -c couchdbtest
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 60
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN NODE TEST ################"
echo "####################################################"

echo y | ./byfn.sh -m up -l node -t 60
echo y | ./eyfn.sh -m up -l node -t 60
echo y | ./eyfn.sh -m down
