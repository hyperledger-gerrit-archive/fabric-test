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
WD="${WORKSPACE}/src/github.com/hyperledger/${REPO_NAME}"
export STABLE_VERSION=${STABLE_VERSION:-1.3.0-stable}
export BASE_VERSION=${BASE_VERSION:-1.3.0}

clean_directory() {

  rm -rf ${WORKSPACE}/src/github.com/hyperledger/fabric-samples
}

clone_repo() {

  git clone --single-branch -b $GERRIT_BRANCH git://cloud.hyperledger.org/mirror/$REPO_NAME $WD

  pushd $WD
  git checkout $FAB_SAMPLES_REL_COMMIT
  popd

  # Display the RELEASE_VERSION to indicate the RELEASE being tested.
  echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
}

# pull fabric binaries
pull_fabric_binaries() {
  PWD=$(pwd)
  echo "------> PWD: ${PWD}"
  export MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
  echo "-------> MARCH:" $MARCH
  echo "-------> pull stable binaries for all platforms (x and z)"
  MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-$STABLE_VERSION/maven-metadata.xml")
  curl -L "$MVN_METADATA" > maven-metadata.xml
  RELEASE_TAG=$(cat maven-metadata.xml | grep release)
  COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
  echo "-------> COMMIT:" $COMMIT
  curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-$STABLE_VERSION/$MARCH.$STABLE_VERSION-$COMMIT/hyperledger-fabric-$STABLE_VERSION-$MARCH.$STABLE_VERSION-$COMMIT.tar.gz | tar xz

  if [ $? != 0 ]; then
    echo "-------> FAILED to pull fabric binaries"
    exit 1
  fi

  cp -r bin $WD/first-network

}

run_tests() {

  pushd $WD/first-network

  ls -l $WD/bin/

  echo "############## BYFN,EYFN DEFAULT CHANNEL TEST ###########"
  echo "#########################################################"

  echo y | ./byfn.sh -m down
  echo y | ./byfn.sh -m up -t 60
  copy_logs $? default-channel
  echo y | ./eyfn.sh -m up -t 60
  copy_logs $? default-channel
  echo y | ./eyfn.sh -m down
  echo
  echo "############## BYFN,EYFN CUSTOM CHANNEL TEST ############"
  echo "#########################################################"

  echo y | ./byfn.sh -m up -c fabricrelease -t 60
  copy_logs $? fabricrelease
  echo y | ./eyfn.sh -m up -c fabricrelease -t 60
  copy_logs $? fabricrelease
  echo y | ./eyfn.sh -m down
  echo
  echo "############# BYFN,EYFN CUSTOM CHANNEL WITH COUCHDB TEST ##############"
  echo "#######################################################################"

  echo y | ./byfn.sh -m up -c fabricrelease-couchdb -s couchdb -t 80 -d 15
  copy_logs $? fabricrelease-couch couchdb
  echo y | ./eyfn.sh -m up -c fabricrelease-couchdb -s couchdb -t 80 -d 15
  copy_logs $? fabricrelease-couch couchdb
  echo y | ./eyfn.sh -m down
  echo
  echo "############### BYFN,EYFN WITH NODE Chaincode. TEST ################"
  echo "####################################################################"

  echo y | ./byfn.sh -m up -l node -t 60
  copy_logs $? default-channel-node
  echo y | ./eyfn.sh -m up -l node -t 60
  copy_logs $? default-channel-node
  echo y | ./eyfn.sh -m down

  popd
}

main() {
  clean_directory
  clone_repo
  cd $WD
  pull_fabric_binaries
  run_tests
}

main
