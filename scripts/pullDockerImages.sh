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

case $REPO in
all)
  echo "Pull all images"
  dockerTag peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv
  ;;
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
esac

echo
docker images | grep "hyperledger*" || true
echo
