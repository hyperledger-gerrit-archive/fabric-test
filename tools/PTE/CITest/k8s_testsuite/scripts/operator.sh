#!/bin/bash -e
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#

while getopts ":s:d:f:t:p:c:i:" opt;
  do
    case $opt in
      s)
        startNw="${OPTARG}"
        ;;
      f)
        nwFile="${OPTARG}"
        ;;
      d) # Down fabric network on k8s
        stopNw="${OPTARG}"
        ;;
      t)  # Execute FAB-3833-2i test case
        testCase="${OPTARG}"
        ;;
      p)  # prerequisite step to install npm
        preReq="${OPTARG}"
        ;;
      c)  # prerequisite step to install npm
        createc="y"
        ;;
      i)  # prerequisite step to install npm
        insta="y"
        ;;
      \?)
        echo "Error: Unrecognized command line argument:"
        exit 1
        ;;
    esac
done

# common test directories
FabricTestDir="$GOPATH"/src/github.com/hyperledger/fabric-test
NLDir="$FabricTestDir"/tools/NL
PTEDir="$FabricTestDir"/tools/PTE
ConnProfile=CITest/CIConnProfiles/test-network

# verify the result
checkResult() {
  if [ "$1" -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! ==========="
    echo
    exit 1
  fi
}

startNw() {
  # Create fabric network on k8s cluster
  cd "$NLDir"/k8s || exit
  # export kubeconfig file to KUBECONFIG
  go run networkLauncher.go -i "$1" -k "$KUBECONFIG"
  res=$?
  checkResult $res "failed to launch the network"

  i=0
  until [ "$(kubectl get pods --field-selector=status.phase!=Running | wc -l)" == 0 ] || [ $i -gt 60 ]; do
    pods=$(kubectl get pods --field-selector=status.phase!=Running | wc -l)
    i=$((i + 1 ))
    echo " ------> Waiting for $pods more pods to start"
  done
  # Copy channel config tx (workaround)
  cd "$GOPATH"/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/crypto-config || exit && mkdir -p ordererOrganizations
  cp -r ../channel-artifacts/*.* ordererOrganizations/
  ls "$GOPATH"/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/crypto-config/ordererOrganizations/
  cd -
}

# Stop Network
stopNw() {
  cd "$NLDir"/k8s || exit
  # provide networkspec 1 and kubeconfig 1 here
  go run networkLauncher.go -i "$1" -k "$KUBECONFIG" -m down
  res=$?
  checkResult $res "Failed to stop the network"
  i=0
  until [ "$(kubectl get pods --field-selector=status.phase=Running | wc -l)" == 0 ] || [ $i -gt 60 ]; do
    pods=$(kubectl get pods --field-selector=status.phase=Running | wc -l)
    i=$((i + 1 ))
    echo " ------> Waiting for $pods more pods to stop"
    sleep 30;
  done
  cd -
}

# install npm node modules
npmInstall() {
  cd "$PTEDir"
  npm install
}

# create/join channel
createJoinChannel() {
  cd "$PTEDir/CITest/scripts"
  echo "-------> Create & Join Channel"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 3 --chanprefix testorgschannel --norg 2 -a samplecc samplejs marbles02 -c > $PTEDir/createChannel.log
}

# install/instantiate chaincode: samplecc samplejs marbles02
installInstantiate() {
  cd "$PTEDir/CITest/scripts"
  # Install and Instantiate chaincode
  echo "-------> Install & Instantiate Chaincode"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 3 --chanprefix testorgschannel --norg 2 -a samplecc samplejs marbles02 -i > $PTEDir/installInstantiate.log
}

# Execute FAB-3833-2i test case wtih samplecc chaincode
FAB-3833-2i() {
  # Execute Test Case
  cd "$PTEDir"/CITest/scripts
  echo "-------> Execute Invoke"
  ./gen_cfgInputs.sh -d "$ConnProfile" -n testorgschannel1 --norg 2 --orgprefix org -a samplecc --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move > $PTEDir/FAB-3833-2i.log
  echo "-------> Execute Query"
  ./gen_cfgInputs.sh -d "$ConnProfile" -n testorgschannel1 --norg 2 --orgprefix org -a samplecc --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t query > $PTEDir/FAB-3833-2q.log
}

# Execute FAB-4038-2i test case wtih samplejs chaincode
FAB-4038-2i() {
  cd "$PTEDir"/CITest/scripts
  echo "-------> Execute Invoke"
  ./gen_cfgInputs.sh -d "$ConnProfile" -n testorgschannel1 --norg 2 --orgprefix org -a samplejs --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move > $PTEDir/FAB-4038-2i.log
  echo "-------> Execute Query"
  ./gen_cfgInputs.sh -d "$ConnProfile" -n testorgschannel1 --norg 2 --orgprefix org -a samplejs --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t query > $PTEDir/FAB-4038-2q.log
}

# Start the network
if [ "$startNw" == "up" ]; then
  startNw "$nwFile"
fi
# Stop the network
if [ "$stopNw" == "down" ]; then
  stopNw "$nwFile"
fi
# Install npm
if [ "$preReq" == "y" ]; then
  npmInstall
fi
if [ "$createc" == "y" ]; then
  createJoinChannel
fi
if [ "$insta" == "y" ]; then
  installInstantiate
fi
# Execute Input testcase
if [ ! -z "$testCase" ]; then
  $testCase
else
  echo "===== Provide test case name ===="
fi
