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
WD="${GOPATH}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples
NEXUS_REPO_URL=https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric

clean_directory() {
  rm -rf ${GOPATH}/src/github.com/hyperledger/fabric-samples
}

clone_repo() {
  git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME \
  $WD
  cd $WD

  # Display the RELEASE_VERSION to indicate the RELEASE being tested.
  echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
}

run_tests() {
  cd $WD/first-network

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

}

main() {
  clean_directory
  clone_repo
  run_tests
}

main
