#!/bin/bash -ue

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Test Java SDK e2e tests
#
rm -rf ${GOPATH}/src/github.com/hyperledger/fabric-sdk-java
WD="${GOPATH}/src/github.com/hyperledger/fabric-sdk-java"
git clone https://github.com/hyperledger/fabric-sdk-java $WD
# checkout to latest release tag
cd $WD

#curl -L https://raw.githubusercontent.com/hyperledger/fabric/${GERRIT_BRANCH}/Makefile > Makefile
#RELEASE_VERSION=$(cat Makefile | grep "BASE_VERSION =" | awk '{print $3}')
echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
git checkout tags/v$RELEASE_VERSION

#Delete temporary Makefile.
rm -rf Makefile

export GOPATH=$WD/src/test/fixture
cd $WD/src/test
./cirun.sh
