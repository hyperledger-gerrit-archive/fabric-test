#!/bin/bash -ue
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################
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
