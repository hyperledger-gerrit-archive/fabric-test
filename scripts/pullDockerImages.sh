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

  # Pulling an exact image until the latest tag is set correctly
  docker pull $NEXUS_URL/$ORG_NAME-peer:amd64-1.4.0-stable-1aa5b47
  docker tag $NEXUS_URL/$ORG_NAME-peer:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-peer
  docker tag $NEXUS_URL/$ORG_NAME-peer:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-peer:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-peer:amd64-1.4.0-stable-1aa5b47

  docker pull $NEXUS_URL/$ORG_NAME-orderer:amd64-1.4.0-stable-1aa5b47
  docker tag $NEXUS_URL/$ORG_NAME-orderer:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-orderer
  docker tag $NEXUS_URL/$ORG_NAME-orderer:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-orderer:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-orderer:amd64-1.4.0-stable-1aa5b47

  docker pull $NEXUS_URL/$ORG_NAME-ccenv:amd64-1.4.0-stable-1aa5b47
  docker tag $NEXUS_URL/$ORG_NAME-ccenv:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-ccenv
  docker tag $NEXUS_URL/$ORG_NAME-ccenv:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-ccenv:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-ccenv:amd64-1.4.0-stable-1aa5b47

  docker pull $NEXUS_URL/$ORG_NAME-tools:amd64-1.4.0-stable-1aa5b47
  docker tag $NEXUS_URL/$ORG_NAME-tools:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-tools
  docker tag $NEXUS_URL/$ORG_NAME-tools:amd64-1.4.0-stable-1aa5b47 $ORG_NAME-tools:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-tools:amd64-1.4.0-stable-1aa5b47

  docker pull $NEXUS_URL/$ORG_NAME-ca-tools:amd64-1.4.0-stable-afa77f9
  docker tag $NEXUS_URL/$ORG_NAME-ca-tools:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca-tools
  docker tag $NEXUS_URL/$ORG_NAME-ca-tools:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca-tools:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-ca-tools:amd64-1.4.0-stable-afa77f9

  docker pull $NEXUS_URL/$ORG_NAME-ca-orderer:amd64-1.4.0-stable-afa77f9
  docker tag $NEXUS_URL/$ORG_NAME-ca-orderer:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca-orderer
  docker tag $NEXUS_URL/$ORG_NAME-ca-orderer:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca-orderer:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-ca-orderer:amd64-1.4.0-stable-afa77f9

  docker pull $NEXUS_URL/$ORG_NAME-ca-peer:amd64-1.4.0-stable-afa77f9
  docker tag $NEXUS_URL/$ORG_NAME-ca-peer:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca-peer
  docker tag $NEXUS_URL/$ORG_NAME-ca-peer:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca-peer:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-ca-peer:amd64-1.4.0-stable-afa77f9

  docker pull $NEXUS_URL/$ORG_NAME-ca:amd64-1.4.0-stable-afa77f9
  docker tag $NEXUS_URL/$ORG_NAME-ca:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca
  docker tag $NEXUS_URL/$ORG_NAME-ca:amd64-1.4.0-stable-afa77f9 $ORG_NAME-ca:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-ca:amd64-1.4.0-stable-afa77f9

  docker pull $NEXUS_URL/$ORG_NAME-javaenv:amd64-1.4.0-stable-3b61085
  docker tag $NEXUS_URL/$ORG_NAME-javaenv:amd64-1.4.0-stable-3b61085 $ORG_NAME-javaenv
  docker tag $NEXUS_URL/$ORG_NAME-javaenv:amd64-1.4.0-stable-3b61085 $ORG_NAME-javaenv:$LATEST_TAG
  docker rmi -f $NEXUS_URL/$ORG_NAME-javaenv:amd64-1.4.0-stable-3b61085

#  for IMAGE in $IMAGELIST; do
#    echo "Image: $IMAGE"
#    echo
#    docker pull $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG
#          if [ $? != 0 ]; then
#             echo  "FAILED: Docker Pull Failed on $IMAGE"
#             exit 1
#          fi
#    docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG $ORG_NAME-$IMAGE
#    docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG $ORG_NAME-$IMAGE:$LATEST_TAG
#    echo "$ORG_NAME-$IMAGE:$LATEST_TAG"
#    echo "Deleting Nexus docker images: $IMAGE"
#    docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGE:$LATEST_TAG
#  done
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
*)
  echo "Pull all images"
  dockerTag peer orderer ccenv tools ca ca-tools ca-peer ca-orderer ca-fvt javaenv
  ;;
esac

echo
docker images | grep "hyperledger*" || true
echo
