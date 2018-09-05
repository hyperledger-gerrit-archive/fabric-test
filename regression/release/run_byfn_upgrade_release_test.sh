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
WD="${WORKSPACE}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples
NEXUS_REPO_URL=https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric

clean_directory() {
  rm -rf $WD
}

clone_repo() {

  git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
  pushd $WD
  git checkout $GERRIT_BRANCH
  git checkout $FAB_SAMPLES_REL_COMMIT

  # Display the RELEASE_VERSION to indicate the RELEASE being tested.
  echo "--------> RELEASE_VERSION : $RELEASE_VERSION"

  popd
}

run_upgrade_test() {
  echo "############### BYFN UPGRADE TEST ################"
  echo "#######################################################"

  curl $NEXUS_REPO_URL/linux-$ARCH-$FABRIC_PREVIOUS_VERSION/hyperledger-fabric-linux-$ARCH-$FABRIC_PREVIOUS_VERSION.tar.gz | tar xz
  pushd $WD/first-network

  git checkout v$FABRIC_PREVIOUS_VERSION
  echo y | ./byfn.sh up -i $FABRIC_PREVIOUS_VERSION
  git checkout master
  echo y | ./byfn.sh upgrade
  echo y | ./byfn.sh -m down

  popd
}

main() {
  # clean_directory
  # clone_repo
  # mkdir -p $WD/bin
  # cd $WD/bin
  # run_upgrade_test
  echo "############### BYFN upgrade test not in use here. ###############"
}

main
