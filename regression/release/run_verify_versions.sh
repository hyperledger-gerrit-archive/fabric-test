#!/bin/bash  -e
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
set -o pipefail
export MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed \
's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | \
awk '{print tolower($0)}')

clean_directory() {
  rm -rf ${WORKSPACE}/src/github.com/hyperledger/fabric
}

clone_repo() {
  WD="${WORKSPACE}/src/github.com/hyperledger/fabric"
  REPO_NAME=fabric

  git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
  pushd $WD
  git checkout $GERRIT_BRANCH
  git checkout $FABRIC_REL_COMMIT
  popd
}

pull_fabric_images() {
  #TODO: Pull Fabric Images
}

pull_fabric_binaries() {
  PWD=$(pwd)
  echo "------> PWD: ${PWD}"
  echo "-------> MARCH:" $MARCH
  echo "-------> pull fabric binaries"
  curl -L "$MVN_METADATA" > maven-metadata.xml
  local RELEASE_TAG=$(cat maven-metadata.xml | grep release)
  local COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
  echo "-------> COMMIT:" $COMMIT
  curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/$MARCH-$RELEASE_VERSION/hyperledger-fabric-$MARCH-$RELEASE_VERSION.tar.gz | tar xz

  if [ $? != 0 ]; then
    echo "-------> FAILED to pull fabric binaries"
    exit 1
  fi
}

# Verify the version built in peer and configtxgen binaries
verify_version() {

  clean_directory
  clone_repo
  pull_fabric_images
  pull_fabric_binaries

  pushd release/linux-amd64/bin

  ./peer version > peer.txt

  Pversion=$(grep -v "Version" peer.txt | grep Version: | awk '{print $2}' | \
  head -n1)

  if [ "$Pversion" != "$RELEASE_VERSION" ]; then
     echo " ===> ERROR !!! Peer Version check failed"
     echo
  fi
  ./configtxgen --version > configtxgen.txt

  Configtxgen=$(grep -v "Version" configtxgen.txt | grep Version: | awk \
  '{print $2}' | head -n1)

  if [ "$Configtxgen" != "$RELEASE_VERSION" ]; then
   echo "====> ERROR !!! configtxgen Version check failed:"
   echo
   exit 1
  fi

  echo "====> PASS !!! Configtxgen version verified:"

  ./orderer --version > orderer.txt

  orderer=$(grep -v "Version" orderer.txt | grep Version: | awk \
  '{print $2}' | head -n1)

  if [ "$orderer" != "$RELEASE_VERSION" ]; then
    echo "====> ERROR !!! orderer Version check failed:"
    echo
    exit 1
  fi

  echo "====> PASS !!! orderer version verified:"

  ./configtxlator --version > configtxlator.txt

  configtxlator=$(grep -v "Version" configtxlator.txt | grep Version: | awk \
  '{print $2}' | head -n1)

  if [ "$configtxlator" != "$RELEASE_VERSION" ]; then
     echo "====> ERROR !!! configtxlator Version check failed:"
     echo
     exit 1
  fi

  echo "====> PASS !!! configtxlator version verified:"
}
