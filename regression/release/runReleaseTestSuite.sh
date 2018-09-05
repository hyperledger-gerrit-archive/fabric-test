#!/bin/bash
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

pull_build_artifacts()
{
  curl -sSL http://bit.ly/2ysbOFE | bash -s $FAB_VER $CA_VER $BASE_VER
  docker pull hyperledger/fabric-javaenv:$FAB_VER
}

run_release_tests()
{
  # TODO: Currently, the step below is not executed. There is an issue
  # with invoking this script from the verify_versions_release_tests.py
  # wrapper that should be addressed.
  # See: https://jira.hyperledger.org/browse/FABCI-245

  # docker rm -f $(docker ps -aq) || true
  # echo "=======> Verify Pull Versions"
  # py.test -v --junitxml results_make_targets.xml verify_versions_release_tests.py

  docker rm -f $(docker ps -aq) || true
  echo "=======> Execute SDK tests..."
  py.test -v --junitxml results_e2e_sdk.xml e2e_sdk_release_tests.py

  docker rm -f $(docker ps -aq) || true
  echo "=======> Execute byfn tests..."
  py.test -v --junitxml results_byfn_cli.xml byfn_release_tests.py

  docker rm -f $(docker ps -aq) || true
  echo "=======> Execute fabcar tests..."
  py.test -v --junitxml results_fabcar.xml fabcar_release_tests.py
}

main()
{
  echo "=====> runReleaseTestSuite.sh"
  pull_build_artifacts
  run_release_tests
}

main
