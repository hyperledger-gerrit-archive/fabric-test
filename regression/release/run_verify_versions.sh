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
set -o pipefail

# Verifies the release version for the peer, configtxgen, orderer,
# configtxlator, and idemixgen binaries. Called in the
# verify_versions_release_tests.py file as ./run_verify_versions verify_version

# TODO: Currently, this script is not executed. There is an issue with invoking
# this script from the verify_versions_release_tests.py wrapper that should
# be addressed. See: https://jira.hyperledger.org/browse/FABCI-245
function verify_versions()
{
  echo "=====> verify_versions()...."
  pushd fabric-samples/bin
  ./peer version
  ./peer version > peer.txt

  cat peer.txt

  Pversion=$(grep -v "Version" peer.txt | grep Version: | \
    awk '{print $2}' | head -n1)

  echo $Pversion

  if [ "$Pversion" != "$RELEASE_VERSION" ]; then
     echo "=====> ERROR !!! Peer Version check failed"
     echo
     exit 1
  fi

  echo "====> PASS !!! Peer version verified."

  ./configtxgen --version > configtxgen.txt

  Configtxgen=$(grep -v "Version" configtxgen.txt | grep Version: | \
    awk '{print $2}' | head -n1)

  if [ "$Configtxgen" != "$RELEASE_VERSION" ]; then
   echo "====> ERROR !!! configtxgen Version check failed:"
   echo
   exit 1
  fi

  echo "====> PASS !!! Configtxgen version verified."

  ./orderer version > orderer.txt

  orderer=$(grep -v "Version" orderer.txt | grep Version: | \
    awk '{print $2}' | head -n1)

  if [ "$orderer" != "$RELEASE_VERSION" ]; then
    echo "====> ERROR !!! orderer Version check failed:"
    echo
    exit 1
  fi

  echo "====> PASS !!! orderer version verified."

  ./configtxlator version > configtxlator.txt

  configtxlator=$(grep -v "Version" configtxlator.txt | grep Version: | \
    awk '{print $2}' | head -n1)

  if [ "$configtxlator" != "$RELEASE_VERSION" ]; then
     echo "====> ERROR !!! configtxlator Version check failed:"
     echo
     exit 1
  fi

  echo "====> PASS !!! configtxlator version verified."

  ./idemixgen version > idemixgen.txt

  idemixgen=$(grep -v "Version" configtxlator.txt | grep Version: | \
    awk '{print $2}' | head -n1)

  if [ "$idemixgen" != "$RELEASE_VERSION" ]; then
     echo "====> ERROR !!! idemixgen Version check failed:"
     echo
     exit 1
  fi

  echo "====> PASS !!! idemixgen version verified."

  popd
}

function main()
{
  echo "=====> run_verify_versions.sh"
  verify_versions
}

main
