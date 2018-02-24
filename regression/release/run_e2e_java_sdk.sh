#!/bin/bash

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
cd $WD && git checkout tags/v1.1.0-alpha
export GOPATH=$WD/src/test/fixture

cd $WD/src/test
chmod +x cirun.sh
source cirun.sh
