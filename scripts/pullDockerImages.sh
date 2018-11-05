#!/bin/bash -e
set -o pipefail

cd $GOPATH/src/github.com/hyperledger/fabric-test

###################
# Install govender
###################
echo "Install govendor"
go get -u github.com/kardianos/govendor

echo "======== PULL DOCKER IMAGES ========"

REPO=$1

##########################################################
# Pull and Tag the fabric and fabric-ca images from Nexus
##########################################################
echo "Fetching images from Nexus"
NEXUS_URL=nexus3.hyperledger.org:10001
ORG_NAME="hyperledger/fabric"
ARCH=$(go env GOARCH)
LATEST_TAG=$ARCH-latest
echo "---------> REPO:" $REPO
echo "---------> LATEST TAG:" $LATEST_TAG

cd $GOPATH/src/github.com/hyperledger/fabric

dockerTag(images) {
  for IMAGES in images; do
    echo "Images: $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$LATEST_TAG
          if [ $? != 0 ]; then
             echo  "FAILED: Docker Pull Failed on $IMAGES"
             exit 1
          fi
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$LATEST_TAG $ORG_NAME-$IMAGES
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$LATEST_TAG $ORG_NAME-$IMAGES:$LATEST_TAG
    echo "$ORG_NAME-$IMAGES:$LATEST_TAG"
    echo "Deleting Nexus docker images: $IMAGES"
    docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$LATEST_TAG
  done
}

case $REPO in
all)
  echo "Pull all images"
  dockerTag(peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv)
  ;;
fabric)
  echo "Pull all images except fabric"
  dockerTag(javaenv tools ca )
  ;;
fabric-ca)
  echo "Pull all images except fabric-ca"
  dockerTag(peer orderer ccenv tools javaenv)
  ;;
fabric-sdk-node)
  echo "Pull all images except fabric-sdk-node"
  dockerTag(peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv)
  ;;
fabric-sdk-java)
  echo "Pull all images except fabric-sdk-java"
  dockerTag(peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv)
  ;;
fabric-javaenv)
  echo "Pull all images except fabric-javaenv"
  dockerTag(peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt)
  ;;
esac

echo
docker images | grep "hyperledger*" || true
echo
