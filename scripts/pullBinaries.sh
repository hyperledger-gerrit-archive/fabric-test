#!/bin/bash -e
set -o pipefail

cd $GOPATH/src/github.com/hyperledger/fabric-test

##########################################################
# Pull the fabric and fabric-ca binaries from Nexus
##########################################################
echo "Fetching binary artifacts from Nexus"
NEXUS_URL=nexus.hyperledger.org
ORG_NAME="hyperledger/fabric"
ARCH=$(go env GOARCH)
LATEST_TAG=$ARCH-latest
echo "---------> REPO:" $REPO
echo "---------> LATEST TAG:" $LATEST_TAG

#####################################################
# Pull fabric binary artifacts with the latest tag
#####################################################
echo "======== PULL FABRIC BINARIES ========"
echo
rm -rf .build && mkdir -p .build && cd .build
curl https://$NEXUS_URL/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-latest/hyperledger-fabric-$LATEST_TAG.tar.gz | tar xz
export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/.build/bin:$PATH

#####################################################
# Pull fabric-ca binary artifacts with the latest tag
#####################################################
echo "======== PULL FABRIC-CA BINARIES ========"
echo
curl https://$NEXUS_URL/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca-latest/hyperledger-fabric-ca-$LATEST_TAG.tar.gz | tar xz
export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/.build/bin:$PATH

##################
# Show the results
##################
echo "Binaries fetched from Nexus"
echo
ls -l bin/
echo
