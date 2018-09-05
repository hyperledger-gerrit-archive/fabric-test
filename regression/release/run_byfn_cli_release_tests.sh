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
BRANCH=${GERRIT_BRANCH:=master}

clean_directory()
{
  rm -rf $WD
}

clone_repo()
{

  git clone --single-branch -b $BRANCH \
    git://cloud.hyperledger.org/mirror/fabric-samples $WD

  (cd $WD; git checkout $FAB_SAMPLES_REL_COMMIT)

}

run_tests()
{

  pushd $WD/first-network

  echo "############## BYFN,EYFN DEFAULT CHANNEL TEST ###########"
  echo "#########################################################"

  echo y | ./byfn.sh -m down
  echo y | ./byfn.sh -m generate
  echo y | ./byfn.sh -m up -t 100

  echo y | ./eyfn.sh -m up -t 100
  echo y | ./eyfn.sh -m down
  echo
  echo "############## BYFN,EYFN CUSTOM CHANNEL TEST ############"
  echo "#########################################################"
  echo y | ./byfn.sh -m generate -c fabricrelease
  echo y | ./byfn.sh -m up -c fabricrelease -t 100
  echo y | ./eyfn.sh -m up -c fabricrelease -t 100
  echo y | ./eyfn.sh -m down
  echo
  echo "############# BYFN,EYFN CUSTOM CHANNEL WITH COUCHDB TEST ##############"
  echo "#######################################################################"
  echo y | ./byfn.sh -m generate -c fabricrelease-couchdb
  echo y | ./byfn.sh -m up -c fabricrelease-couchdb -s couchdb -t 100 -d 15
  echo y | ./eyfn.sh -m up -c fabricrelease-couchdb -s couchdb -t 100 -d 15
  echo y | ./eyfn.sh -m down
  echo
  echo "############### BYFN,EYFN WITH NODE Chaincode. TEST ################"
  echo "####################################################################"
  echo y | ./byfn.sh -m up -l node -t 100
  echo y | ./eyfn.sh -m up -l node -t 100
  echo y | ./eyfn.sh -m down

  popd
}

function clearContainers()
{

  CONTAINER_IDS=$(docker ps -aq)

  if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS || true
    echo "---- Docker containers after cleanup ----"
    docker ps -a
  fi
}

function removeUnwantedImages()
{
  DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" \
  | awk '{print $3}')

  if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" = " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS || true
    echo "---- Docker images after cleanup ----"
    docker images
  fi
}

main()
{
  clean_directory
  clone_repo
  # Copy the binaries from fabric-test
  cd $WD
  cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test/regression/release/fabric-samples/bin/ .
  run_tests
  clearContainers
  removeUnwantedImages
}

main
