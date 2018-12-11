#!/bin/bash -e
set -o pipefail

REPO=$1

###################
# Install govender
###################
echo "Install govendor"
go get -u github.com/kardianos/govendor

echo "======== PULL DOCKER IMAGES ========"
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


dockerTag() {
  IMAGELIST=$@
  echo "Images: $IMAGELIST"

  for IMAGE in $IMAGELIST; do
    echo "Image: $IMAGE"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG
          if [ $? != 0 ]; then
             echo  "FAILED: Docker Pull Failed on $IMAGE"
             exit 1
          fi
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG $ORG_NAME-$IMAGE
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG $ORG_NAME-$IMAGE:$LATEST_TAG
    echo "$ORG_NAME-$IMAGE:$LATEST_TAG"
    echo "Deleting Nexus docker images: $IMAGE"
    docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG
  done
}

dockerThirdParty() {
  for IMAGE in kafka zookeeper couchdb; do
    echo "$ORG_NAME-$IMAGE"
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGE:latest
    if [ $? != 0 ]; then
       echo  "FAILED: Docker Pull Failed on $IMAGE"
       exit 1
    fi
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:latest $ORG_NAME-$IMAGE:latest
    echo "Deleting Nexus docker images: $IMAGE"
    docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGE:latest
  done
}


case $REPO in
fabric)
  echo "Pull all images except fabric"
  dockerTag javaenv tools ca
  ;;
fabric-ca)
  echo "Pull all images except fabric-ca"
  dockerTag peer orderer ccenv tools javaenv
  ;;
fabric-sdk-node)
  echo "Pull all images except fabric-sdk-node"
  dockerTag peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv
  ;;
fabric-sdk-java)
  echo "Pull all images except fabric-sdk-java"
  dockerTag peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv
  ;;
fabric-javaenv)
  echo "Pull all images except fabric-javaenv"
  dockerTag peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt
  ;;
third-party)
  echo "Pull all third-party docker images"
  dockerThirdParty
  ;;
*)
  echo "Pull all images"
  dockerTag peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv
  ;;
esac
#####################################################
# Pull the fabric-chaincode-javaenv image from Nexus
#####################################################
NEXUS_URL=nexus3.hyperledger.org:10001
ORG_NAME="hyperledger/fabric"
IMAGE=javaenv
export RELEASE=1.4.0
export STABLE_VERSION=amd64-$RELEASE-stable
docker pull $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION
docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE
docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-$RELEASE
docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-latest
######################################
docker images | grep hyperledger/fabric-javaenv || true

echo
docker images | grep "hyperledger*"
echo
