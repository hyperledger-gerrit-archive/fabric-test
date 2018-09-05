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

# RUN BYFN Test
#####################
REPO_NAME=fabric-samples
export WD="${WORKSPACE}/src/github.com/hyperledger/${REPO_NAME}"

clean_directory() {
  rm -rf $WD
}

clone_repo() {

  git clone --single-branch -b $GERRIT_BRANCH \
  git://cloud.hyperledger.org/mirror/$REPO_NAME $WD

  pushd $WD
  git checkout $FAB_SAMPLES_REL_COMMIT

}

run_tests() {

  pushd $WD/fabcar

  echo "############## FABCAR TEST ###########"
  echo "######################################"
  ./startFabric.sh

  pushd $WD/fabcar/javascript

  npm install
  node enrollAdmin
  node registerUser
  node invoke
  node query

  popd
}

main() {
  clean_directory
  clone_repo
  cd $WD
  # Copy the binaries from fabric-test
  cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test/regression/release/fabric-samples/bin/ .
  run_tests
}

main
