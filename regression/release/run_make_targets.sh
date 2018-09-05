#!/bin/bash  -e
set -o pipefail
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
rm -rf ${GOPATH}/src/github.com/hyperledger/fabric

WD="${GOPATH}/src/github.com/hyperledger/fabric"
REPO_NAME=fabric

git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD

#RELEASE_VERSION=$(cat Makefile | grep "BASE_VERSION =" | awk '{print $3}')
echo "--------> RELEASE_VERSION : $RELEASE_VERSION"
git checkout tags/v$RELEASE_VERSION

makeCleanAll() {
  make clean-all
  echo "clean-all from fabric repository"
}

# make native
makeNative() {
  make native
  for binary in chaintool configtxgen configtxlator cryptogen orderer peer; do
  	if [ ! -f $CWD/build/bin/$binary ] ; then
     	   echo " ====> ERROR !!! $binary is not available"
     	   echo
           exit 1
        fi

           echo " ====> PASS !!! $binary is available"
  done
}

# Build peer, orderer, configtxgen, cryptogen, discover, idemixgen and
# configtxlator
makeBinary() {
  make clean-all

  for image in configtxgen configtxlator cryptogen discover idemixgen orderer \
  peer; do
   make $image
  done

  for binary in peer orderer configtxgen cryptogen configtxlator; do
   if [ ! -f $WD/.build/bin/$binary ] ; then
     echo " ====> ERROR !!! $binary is not available"
     echo
     exit 1
  fi

  echo " ====> PASS !!! $binary is available"
  done
}

# Create tar files for each platform
makeDistAll() {
  make clean-all
  make dist-all

  for dist in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le \
  linux-s390x; do
    if [ ! -d $CWD/release/$dist ] ; then
      echo " ====> ERROR !!! $dist is not available"
  	  echo
      exit 1
    fi

    echo " ====> PASS !!! $dist is available"
  done
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
