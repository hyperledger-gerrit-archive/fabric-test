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

echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
git checkout tags/v$RELEASE_VERSION

export GOPATH=$WD/src/test/fixture
cd $WD/src/test
./cirun.sh
