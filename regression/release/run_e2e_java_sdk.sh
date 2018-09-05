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

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java"
GOPATH=$WD/src/test/fixture
BRANCH=${GERRIT_BRANCH:=master}

clean_directory() {
  rm -rf $WD
}

clone_repo() {
  git clone --single-branch -b $BRANCH \
    https://github.com/hyperledger/fabric-sdk-java $WD

  cd $WD
  git checkout $JAVA_REL_COMMIT
}

run_e2e_java_tests() {
  (
  cd $WD/src/test
  GOPATH=$PWD/fixture ./cirun.sh
  )
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
  run_e2e_java_tests
  clearContainers
  removeUnwantedImages
}

main
