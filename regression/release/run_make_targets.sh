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
rm -rf ${WORKSPACE}/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/src/github.com/hyperledger/fabric"
REPO_NAME=fabric

git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD
git checkout $GERRIT_BRANCH
git checkout $FABRIC_REL_COMMIT

#echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
#git checkout $RELEASE_COMMIT

makeCleanAll() {
  make clean-all
  echo "clean-all from fabric repository"
}

# Verify the version built in peer and configtxgen binaries
makeVersion() {
  make docker-clean
  make release
  cd release/linux-amd64/bin
  ./peer version > peer.txt
  Pversion=$(grep -v "Version" peer.txt | grep Version: | awk '{print $2}' | head -n1)
      if [ "$Pversion" != "$RELEASE_VERSION" ]; then
         echo " ===> ERROR !!! Peer Version check failed"
         echo
      fi
 ./configtxgen --version > configtxgen.txt
 Configtxgen=$(grep -v "Version" configtxgen.txt | grep Version: | awk '{print $2}' | head -n1)
      if [ "$Configtxgen" != "$RELEASE_VERSION" ]; then
         echo "====> ERROR !!! configtxgen Version check failed:"
         echo
         exit 1
      fi
         echo "====> PASS !!! Configtxgen version verified:"
 ./orderer --version > orderer.txt
 orderer=$(grep -v "Version" orderer.txt | grep Version: | awk '{print $2}' | head -n1)
      if [ "$orderer" != "$RELEASE_VERSION" ]; then
         echo "====> ERROR !!! orderer Version check failed:"
         echo
         exit 1
      fi
         echo "====> PASS !!! orderer version verified:"

 ./configtxlator --version > configtxlator.txt
 configtxlator=$(grep -v "Version" configtxlator.txt | grep Version: | awk '{print $2}' | head -n1)
      if [ "$configtxlator" != "$RELEASE_VERSION" ]; then
         echo "====> ERROR !!! configtxlator Version check failed:"
         echo
         exit 1
      fi
         echo "====> PASS !!! configtxlator version verified:"
}
