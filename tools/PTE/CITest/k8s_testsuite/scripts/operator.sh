#!/bin/bash -e
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#

while getopts ":s:d:f:t:p:" opt;
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
K8sSuite="$PTEDir"/CITest/k8s_testsuite
ConnProfile="$PTEDir"/CITest/CIConnProfiles/test-network

# verify the result
checkResult() {
  if [ $1 -ne 0 ]; then
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
  go run networkLauncher.go -i "$file" -k "$KUBECONFIG" -m down
  res=$?
  checkResult $res "Failed to stop the network"
  i=0
  until [ "$(kubectl get pods --field-selector=status.phase=Running | wc -l)" == 0 ] || [ $i -gt 60 ]; do
    pods=$(kubectl get pods --field-selector=status.phase=Running | wc -l)
    i=$((i + 1 ))
    echo " ------> Waiting for "$pods" more pods to stop"
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
  cd "$PTEDir"
  echo "-------> Create Channel"
  ./pte_driver.sh CITest/"$1"/preconfig/channels/runCases-chan-create-TLS.txt && sleep 20

  echo "-------> Join Channel"
  ./pte_driver.sh CITest/"$1"/preconfig/channels/runCases-chan-join-TLS.txt && sleep 30
  cd -
}

# install/instantiate chaincode: samplecc samplejs marbles02
installInstantiate() {
  cd "$PTEDir"
  # Install
  echo "-------> Install Chaincode"
  ./pte_driver.sh CITest/"$1"/preconfig/samplecc/runCases-samplecc-install-TLS.txt && sleep 20

  # Instantiate
  echo "-------> Instantiate Chaincode"
  ./pte_driver.sh CITest/"$1"/preconfig/samplecc/runCases-samplecc-instantiate-TLS.txt && sleep 60
  cd -
}

# Execute FAB-3833-2i test case
FAB-3833-2i() {
  # Create Channel
  #createJoinChannel FAB-3833-2i
  # Install & Instantiate
  installInstantiate FAB-3833-2i
  # Execute Test Case
  cd "$PTEDir"/CITest/scripts
  echo "-------> Execute FAB-3833-2i TestCase"
  ./test_driver.sh -t FAB-3833-2i
  cd -
}

# Execute FAB-3810-2q test case
FAB-3810-2q() {
  # Execute Test Case
  cd "$PTEDir"/CITest/scripts
  echo "-------> Execute FAB-3810-2q TestCase"
  ./test_driver.sh -t FAB-3810-2q
  cd -
}

# Start the network
if [ "$startNw" == "up" ]; then
  startNw $nwFile
fi
# Stop the network
if [ "$stopNw" == "down" ]; then
  stopNw $nwFile
fi
# Install npm
if [ "$preReq" == "y" ]; then
  npmInstall
fi
# Execute Input testcase
if [ ! -z "$testCase" ]; then
  $testCase
else
  echo "===== Provide test case name ===="
fi
