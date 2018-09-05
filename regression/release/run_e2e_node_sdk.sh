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
export WD="${WORKSPACE}/src/github.com/hyperledger/fabric-sdk-node"
export SDK_REPO_NAME=fabric-sdk-node

clean_directory() {
  rm -rf $WD
}

clone_repo() {
  git clone https://github.com/hyperledger/$SDK_REPO_NAME $WD
  pushd $WD
  git checkout $GERRIT_BRANCH
  git checkout $FABRIC_SDK_NOD_REL_COMMIT
  popd
}

# pull_build_artifacts() {
#   docker pull hyperledger/fabric-javaenv:$FABRIC_TAG
#   docker tag hyperledger/fabric-javaenv:$FABRIC_TAG hyperledger/fabric-javaenv:$FABRIC_TAG
# }

run_gulp_tests() {
  pushd $WD
  wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.4/install.sh | bash
  # shellcheck source=/dev/null
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

  # Install nodejs version 8.11.3
  nvm install 8.11.3

  # use nodejs 8.11.3 version
  nvm use --delete-prefix v8.11.3

  echo "npm version ======>"
  npm -v
  echo "node version =======>"
  node -v

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

remove_test_containers(){
  docker rm -f "$(docker ps -aq)" || true
}

main() {
  clean_directory
  clone_repo
  run_gulp_tests
  remove_test_containers
}

main
