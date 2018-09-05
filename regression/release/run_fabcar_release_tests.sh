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
export PATH=$WD/bin:$PATH

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
  (
  cd $WD/fabcar

  echo "############## FABCAR TEST ###########"
  echo "######################################"

  LANGUAGES="go javascript typescript"
  for LANGUAGE in ${LANGUAGES}; do
    echo -e "\033[32m starting fabcar test (${LANGUAGE})" "\033[0m"
    # Start Fabric, and deploy the smart contract
    ./startFabric.sh ${LANGUAGE}

    # If an application exists for this language, test it
    if [ -d ${LANGUAGE} ]; then
      pushd ${LANGUAGE}
      if [ ${LANGUAGE} = "javascript" ]; then
        COMMAND=node
        PREFIX=
        SUFFIX=.js
        npm install
      elif [ ${LANGUAGE} = "typescript" ]; then
        COMMAND=node
        PREFIX=dist/
        SUFFIX=.js
        npm install
        npm run build
      fi

      ${COMMAND} ${PREFIX}enrollAdmin${SUFFIX}
      ${COMMAND} ${PREFIX}registerUser${SUFFIX}
      ${COMMAND} ${PREFIX}query${SUFFIX}
      ${COMMAND} ${PREFIX}invoke${SUFFIX}

      popd
    fi
    docker ps -aq | xargs docker rm -f
    docker rmi -f $(docker images -aq dev-*)
    echo -e "\033[32m finished fabcar test (${LANGUAGE})" "\033[0m"
  )
}

main()
{
  clean_directory
  clone_repo
  # Copy the binaries from fabric-test
  cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test/regression/release/fabric-samples/bin/ .
  run_tests
}

main
