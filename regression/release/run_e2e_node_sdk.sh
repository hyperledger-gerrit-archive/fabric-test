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
WD="${WORKSPACE}/src/github.com/hyperledger/fabric-sdk-node"
:${GERRIT_BRANCH:=master}

clean_directory() {
  rm -rf $WD
}

clone_repo() {
  git clone --single-branch -b $GERRIT_BRANCH \
    https://github.com/hyperledger/fabric-sdk-node $WD
  (
  cd $WD
  git checkout $FABRIC_SDK_NOD_REL_COMMIT
  )
}

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
  nvm use --delete-prefix v8.11.3 --silent

  echo "npm version ======>"
  npm -v
  echo "node version =======>"
  node -v

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
  istanbul cover --report cobertura test/integration/e2e.js

  popd
}

function clearContainers() {

  CONTAINER_IDS=$(docker ps -aq)

  if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS || true
    echo "---- Docker containers after cleanup ----"
    docker ps -a
  fi
}

function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" \
  | awk '{print $3}')

  if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" = " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS || true
    echo "---- Docker images after cleanup ----"
    docker images
  fi
}

function main() {
  clean_directory
  clone_repo
  run_gulp_tests
  clearContainers
  removeUnwantedImages
}

main
