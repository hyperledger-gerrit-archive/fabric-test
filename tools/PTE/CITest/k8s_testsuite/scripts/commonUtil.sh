#!/bin/bash -e
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#

# usage
usage () {
    echo -e "\nUsage:\t./commonUtils.sh -d <stop the network> -s <create the network> -FAB-3833-2i"
    echo
    echo -e "\t-h, --help\tView this help message"
    echo
    echo -e "\t-d, --stopnw\tStop fabric network"
    echo
    echo -e "\t-s, --startnw\tCreate fabric network on k8s"
    echo
    echo -e "\t-FAB-3833-2i, ---FAB-3833-2i\tExecutes FAB-3833-2i test case"
    echo
    echo -e "\tExamples:"
    echo -e "\t    ./commonUtils.sh -d -s -FAB-3833-2i"
    echo
}

# common test directories
FabricTestDir=$GOPATH/src/github.com/hyperledger/fabric-test
NLDir=$FabricTestDir/tools/NL
PTEDir=$FabricTestDir/tools/PTE
K8sSuite=$PTEDir/CITest/k8s_testsuite
ConnProfile=$PTEDir/CITest/CIConnProfiles/test-network

# Create fabric network on k8s cluster
startnw() {
  cd $NLDir/k8s
  # provide networkspec file and kubeconfig file here
  go run networkLauncher.go -i $K8sSuite/networkSpecFiles/network1spec.yaml -k $KUBECONFIG
  i=0
  until [ "$(kubectl get pods --field-selector=status.phase!=Running | wc -l)" == 0 ] || [ $i -gt 60 ]; do
    pods=$(kubectl get pods --field-selector=status.phase!=Running | wc -l)
    i=$((i + 1 ))
    echo " ------> Waiting for $pods more pods to start"
  done
  # Copy channel config files
  cd $GOPATH/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/crypto-config && mkdir -p ordererOrganizations
  cp -r ../channel-artifacts/*.* ordererOrganizations/
  ls GOPATH/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/crypto-config/ordererOrganizations/
  cd -
}

# Stop Network
stopnw() {
  cd $NLDir/k8s
  # provide networkspec file and kubeconfig file here
  go run networkLauncher.go -i $K8sSuite/networkSpecFiles/network1spec.yaml -k $KUBECONFIG -m down
  i=0
  until [ "$(kubectl get pods --field-selector=status.phase=Running | wc -l)" == 0 ] || [ $i -gt 60 ]; do
    pods=$(kubectl get pods --field-selector=status.phase=Running | wc -l)
    i=$((i + 1 ))
    echo " ------> Waiting for $pods more pods to stop"
    sleep 30;
  done
  cd -
}

npmInstall() {
  cd $PTEDir
  npm install
}
# create/join channel
createJoinChannel() {
  cd $PTEDir
  echo "-------> Create Channel"
  ./pte_driver.sh CITest/$1/preconfig/channels/runCases-chan-create-TLS.txt && sleep 15
  #./gen_cfgInputs.sh -d $ConnProfile --tls serverauth --nchan 3 --chan0 0 --chanprefix testorgschannel --norg 2 -c
  echo "-------> Join Channel"
  ./pte_driver.sh CITest/$1/preconfig/channels/runCases-chan-join-TLS.txt && sleep 15
  cd -
}

# install/instantiate chaincode: samplecc samplejs marbles02
installInstantiate() {
   cd $PTEDir
  echo "-------> Install Chaincode"
  # Install
  ./pte_driver.sh CITest/$1/preconfig/samplecc/runCases-samplecc-install-TLS.txt && sleep 15
  echo "-------> Instantiate Chaincode"
  # Instantiate
  ./pte_driver.sh CITest/$1/preconfig/samplecc/runCases-samplecc-instantiate-TLS.txt && sleep 20
   
#  cd $CMDDir
#  ./gen_cfgInputs.sh -d $ConnProfile --tls serverauth --nchan 3 --chan0 0 --chanprefix testorgschannel --norg 2 -a samplecc samplejs marbles02 -i
  cd -
}

# Execute FAB-3833-2i test case
FAB-3833-2i() {
  # Install latest npm node modules
  npmInstall
  # Create Channel
  createJoinChannel FAB-3833-2i
  # Install & Instantiate
  installInstantiate FAB-3833-2i
  cd $PTEDir/CITest/scripts
  echo "-------> Execute FAB-3833-2i TestCase"
  # Execute Test Case
  ./test_driver.sh -t FAB-3833-2i
  cd -
}

# Inpute Parameters
while [[ $# -gt 0 ]]; do
    arg="$1"

    case $arg in

       -h | --help)
          usage              # displays usage info
          exit 0             # exit cleanly, since the use just asked for help/usage info
          ;;
      -s | --startnw)
          startnw              # Start fabric network on k8s cluster
          shift
          ;;
      -d | --stopnw)           # Down fabric network on k8s
          stopnw
          shift
          ;;
      -FAB-3833-2i | --FAB-3833-2i)  # Execute FAB-3833-2i test case
          FAB-3833-2i
          shift
          ;;
      *)
          echo "Error: Unrecognized command line argument: $1"
          usage
          exit 1
          ;;
    esac
done
