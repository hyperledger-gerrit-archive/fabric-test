#!/bin/bash -e

#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#

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
  #curl -L https://raw.githubusercontent.com/hyperledger/fabric/${GERRIT_BRANCH}/Makefile > Makefile
  #RELEASE_VERSION=$(cat Makefile | grep "BASE_VERSION =" | awk '{print $3}')
  echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
  git checkout tags/v$RELEASE_VERSION

  #Delete temporary Makefile.
  rm -rf Makefile

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
