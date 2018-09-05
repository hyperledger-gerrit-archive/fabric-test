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
export MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed \
's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | \
awk '{print tolower($0)}')
export MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/maven-metadata.xml")

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

  pushd $WD/first-network

  echo "############## BYFN,EYFN DEFAULT CHANNEL TEST ###########"
  echo "#########################################################"

  echo y | ./byfn.sh -m down
  echo y | ./byfn.sh -m up -t 60

  echo y | ./eyfn.sh -m up -t 60
  echo y | ./eyfn.sh -m down
  echo
  echo "############## BYFN,EYFN CUSTOM CHANNEL TEST ############"
  echo "#########################################################"

  echo y | ./byfn.sh -m up -c fabricrelease -t 60

  echo y | ./eyfn.sh -m up -c fabricrelease -t 60
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

  echo y | ./eyfn.sh -m up -l node -t 60
  echo y | ./eyfn.sh -m down

  echo y | ./byfn.sh -m up -l java -t 60
  echo y | ./eyfn.sh -m up -l java -t 60
  echo y | ./eyfn.sh -m down

  popd
}

main() {
  clean_directory
  clone_repo
  cd $WD
  # Copy the binaries from fabric-test
  cp -r ../fabric-test/regression/release/bin/ .
  run_tests
}

main
