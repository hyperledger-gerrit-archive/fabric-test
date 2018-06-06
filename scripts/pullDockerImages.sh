#!/bin/bash -e
set -o pipefail

cd $GOPATH/src/github.com/hyperledger/fabric-test

echo "------> Update fabric-test submodules and install nodejs"

for TARGET in git-init git-latest fabric ca clean pre-setup; do
  echo "------> $TARGET"
  make $TARGET
    if [ $? != 0 ]; then
      echo "------> make $TARGET failed to execute"
      echo
    else
      echo "------> make $TARGET is successful"
      echo
    fi
done

###################
# Install govender
###################
echo "------> Install govendor"
go get -u github.com/kardianos/govendor

##########################################################
# Pull and Tag the fabric and fabric-ca images from Nexus
##########################################################
echo "------> Fetching images from Nexus"
PROJECT_VERSION=1.2.0-stable
NEXUS_URL=nexus3.hyperledger.org:10001
ORG_NAME="hyperledger/fabric"
ARCH=$(go env GOARCH)
STABLE_TAG=$ARCH-$PROJECT_VERSION

cd $GOPATH/src/github.com/hyperledger/fabric

dockerTag() {
  for IMAGES in peer orderer ccenv tools ca; do
    echo "------> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES:$STABLE_TAG
    echo "------> $ORG_NAME-$IMAGES:$STABLE_TAG"
    echo "------> Deleting Nexus docker images: $IMAGES"
    docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
  done
}

dockerTag

#####################################################################
# List all hyperledger docker images and binaries fetched from Nexus
#####################################################################
docker images | grep "hyperledger*"
echo

##########################################
# Fetch the published binaries from Nexus
##########################################

MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/maven-metadata.xml")
curl -L "$MVN_METADATA" > maven-metadata.xml
RELEASE_TAG=$(cat maven-metadata.xml | grep release)
COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
VERSION=$(cat Makefile | grep "BASE_VERSION =" | cut -d "=" -f2 | cut -d " " -f2)
OS_VER=$(uname -s|tr '[:upper:]' '[:lower:]')
echo "------> BASE_VERSION = $VERSION"
echo
rm -rf .build && mkdir -p .build && cd .build
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/$OS_VER-$ARCH.$VERSION-stable-$COMMIT/hyperledger-fabric-stable-$OS_VER-$ARCH.$VERSION-stable-$COMMIT.tar.gz | tar xz
export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/.build/bin:$PATH
echo "------>  Binaries fetched from Nexus"
echo
ls -l bin/
echo
