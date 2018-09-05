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
}

run_e2e_java_tests() {
  pushd $WD/src/test
  ./cirun.sh
  popd
}

main() {
  clean_directory
  clone_repo
  run_e2e_java_tests
}

main
