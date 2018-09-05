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
export WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java"
export GOPATH=$WD/src/test/fixture

clean_directory() {
  rm -rf $WD
}

clone_repo() {
  git clone https://github.com/hyperledger/fabric-sdk-java $WD
  pushd $WD
  git checkout master
  git checkout $JAVA_REL_COMMIT
}

run_e2e_java_tests() {
  pushd $WD/src/test
  ./cirun.sh
  popd
}

remove_test_containers(){
  docker rm -f "$(docker ps -aq)" || true
}

remove_test_images() {
  DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" = " " ]; then
          echo "---- No images available for deletion ----"
  else
          docker rmi -f $DOCKER_IMAGE_IDS || true
          echo "---- Docker images after cleanup ----"
          docker images
  fi
}

main() {
  clean_directory
  clone_repo
  run_e2e_java_tests
  remove_test_containers
  remove_test_images
}

main
