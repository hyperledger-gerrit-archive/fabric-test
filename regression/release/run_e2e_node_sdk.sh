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
WD="${WORKSPACE}/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node

clean_directory() {
  rm -rf $WORKSPACE/src/github.com/hyperledger/fabric-sdk-node
}

clone_repo() {
  git clone https://github.com/hyperledger/$SDK_REPO_NAME $WD
  pushd $WD
  git checkout $GERRIT_BRANCH
  git checkout $FABRIC_SDK_NOD_REL_COMMIT
  popd
}

run_gulp_tests() {
  pushd $WD

  echo "--------> RELEASE_VERSION : $RELEASE_VERSION"

  # Install nvm to install multi node versions
  wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
  # shellcheck source=/dev/null
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

  echo "------> Install NodeJS"

  NODE_VER=8.11.3
  echo "------> Use $NODE_VER for master"
  nvm install $NODE_VER

  # use nodejs 8.11.3 version
  nvm use --delete-prefix v$NODE_VER --silent

  npm install
  npm config set prefix ~/npm
  npm install -g gulp
  npm install -g istanbul
  gulp
  gulp ca
  rm -rf node_modules/fabric-ca-client
  npm install
  gulp test

  popd
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
