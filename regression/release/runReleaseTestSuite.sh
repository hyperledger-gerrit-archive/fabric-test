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

DAILYDIR="$GOPATH/src/github.com/hyperledger/fabric/test/regression/daily"
RELEASEDIR="$GOPATH/src/github.com/hyperledger/fabric/test/regression/release"
export FABRIC_ROOT_DIR=$GOPATH/src/github.com/hyperledger/fabric

run_release_tests() {
  pushd $RELEASEDIR

  docker rm -f $(docker ps -aq) || true
  echo "=======> Execute make targets"
  chmod +x run_make_targets.sh
  py.test -v --junitxml results_make_targets.xml make_targets_release_tests.py

  echo "=======> Execute SDK tests..."
  chmod +x run_e2e_node_sdk.sh
  chmod +x run_e2e_java_sdk.sh
  py.test -v --junitxml results_e2e_sdk.xml e2e_sdk_release_tests.py

  docker rm -f $(docker ps -aq) || true
  echo "=======> Execute byfn tests..."
  chmod +x run_byfn_cli_release_tests.sh
  chmod +x run_node_sdk_byfn.sh
  py.test -v --junitxml results_byfn_cli.xml byfn_release_tests.py

  popd

  pushd $DAILYDIR

  docker rm -f $(docker ps -aq) || true
  echo "=======> Ledger component performance tests..."
  py.test -v --junitxml results_ledger_lte.xml ledger_lte.py

  popd
}

main() {
  run_release_tests
}

main
