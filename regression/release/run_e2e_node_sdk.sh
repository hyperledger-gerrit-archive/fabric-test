#!/bin/bash -e
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
WD="$GOPATH/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node

clean_directory() {
  rm -rf $GOPATH/src/github.com/hyperledger/fabric-sdk-node
}

clone_repo() {
  git clone https://github.com/hyperledger/$SDK_REPO_NAME $WD
}

run_gulp_tests() {
  cd $WD

  echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
  git checkout $RELEASE_COMMIT

  npm install
  npm config set prefix ~/npm
  npm install -g gulp
  npm install -g istanbul
  gulp
  gulp ca
  rm -rf node_modules/fabric-ca-client
  npm install
  gulp test
}

remove_test_image(){
  docker rm -f "$(docker ps -aq)" || true
}

main() {
  clean_directory
  clone_repo
  run_gulp_tests
  remove_test_image
}

main
