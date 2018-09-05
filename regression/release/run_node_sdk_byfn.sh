#!/bin/bash -eu
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

# RUN END-to-END Test
#####################
export WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
export SDK_REPO_NAME=fabric-sdk-node

function clean_directory() {
  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node
}

function clone_repo() {
  git clone git://cloud.hyperledger.org/mirror/$SDK_REPO_NAME $WD
  pushd $WD
  git checkout $GERRIT_BRANCH
  git checkout $FABRIC_SDK_NOD_REL_COMMIT

  popd
}

function run_node_tests() {
  pushd $WD/test/fixtures
  cat docker-compose.yaml > docker-compose.log
  docker-compose up >> dockerlogfile.log 2>&1 &
  sleep 10
  docker ps -a
  pushd ../..
  npm install
  npm config set prefix ~/npm
  npm install -g gulp
  npm install -g istanbul
  gulp
  gulp ca
  rm -rf node_modules/fabric-ca-client
  npm install
  node test/integration/e2e.js

  popd
}

main() {
  clean_directory
  clone_repo
  run_node_tests
}

main
