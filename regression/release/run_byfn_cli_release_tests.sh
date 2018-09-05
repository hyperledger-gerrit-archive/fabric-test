#!/bin/bash -ue
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# RUN BYFN Test
#####################
WD="${GOPATH}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

#CH_NAME="$1"
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

run_bootstrap() {
  # Run the environment bootstrap script, passing in the RELEASE_VERSION to
  # ensure that the correct project versions are used.
  curl -sSL https://goo.gl/6wtTN5 | bash -s $RELEASE_VERSION
}

run_tests() {
  cd $WD/first-network

  echo "############## BYFN,EYFN DEFAULT CHANNEL TEST#############"
  echo "#########################################################"
  echo y | ./byfn.sh -m down
  echo y | ./byfn.sh -m generate
  echo y | ./byfn.sh -m up -t 60
  echo y | ./eyfn.sh -m up
  echo y | ./eyfn.sh -m down
  echo
  echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
  echo "#########################################################"

  echo y | ./byfn.sh -m generate -c fabricrelease
  echo y | ./byfn.sh -m up -c fabricrelease -t 60
  echo y | ./eyfn.sh -m up -c fabricrelease -t 60
  echo y | ./eyfn.sh -m down
  echo
  echo "############### BYFN,EYFN COUCHDB TEST #############"
  echo "####################################################"

  echo y | ./byfn.sh -m generate -c couchdbtest
  echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
  echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 60
  echo y | ./eyfn.sh -m down
  echo
  echo "############### BYFN,EYFN NODE TEST ################"
  echo "####################################################"

  echo y | ./byfn.sh -m up -l node -t 60
  echo y | ./eyfn.sh -m up -l node -t 60
  echo y | ./eyfn.sh -m down


  echo "############### FABRIC-CA SAMPLES TEST ########################"
  echo "###############################################################"
  cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples/fabric-ca
  ./start.sh && ./stop.sh
}

main() {
  clean_directory
  clone_repo
  run_bootstrap
  run_tests
}

main
