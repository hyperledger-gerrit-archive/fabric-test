#!/bin/bash

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#     

rm -rf $GOPATH/src/github.com/hyperledger/fabric-sdk-node

WD="$GOPATH/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone https://github.com/hyperledger/$SDK_REPO_NAME $WD
cd $WD
# checkout to latest release tag
git checkout tags/v1.1.0-alpha
npm install && npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp || true
gulp ca || true
rm -rf node_modules/fabric-ca-client && npm install
gulp test

docker rm -f "$(docker ps -aq)" || true
