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
###############
WD="${WORKSPACE}/src/github.com/hyperledger/fabric-samples"
BRANCH=${GERRIT_BRANCH:=master}

clean_directory() {
  rm -rf $WD
}

clone_repo() {

  git clone --single-branch -b $BRANCH \
    git://cloud.hyperledger.org/mirror/fabric-samples $WD

  (
  cd $WD
  git checkout $FAB_SAMPLES_REL_COMMIT
  )

}

run_tests() {

  (
  cd $WD/fabcar

  echo "############## FABCAR TEST ###########"
  echo "######################################"
  ./startFabric.sh
  )

  (
  cd $WD/fabcar/javascript

  npm install
  node enrollAdmin
  node registerUser
  node invoke
  node query
  )
}

main() {
  clean_directory
  clone_repo
  # Copy the binaries from fabric-test
  cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test/regression/release/fabric-samples/bin/ .
  run_tests
}

main
