#!/bin/bash -e
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#

while getopts ":a:t:p:ic" opt;
  do
    case $opt in
      a)
        action="${OPTARG}"
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
OperatorDir="$FabricTestDir"/tools/operator
PTEDir="$FabricTestDir"/tools/PTE
ConnProfile=CITest/CIConnProfiles/test-network
Chantxpath="github.com/hyperledger/fabric-test/fabric/internal/cryptogen/ordererOrganizations"

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
  cd "$OperatorDir"/launcher || exit
  # export kubeconfig file to KUBECONFIG
  go run launcher.go -i "$PTEDir"/CITest/k8s_testsuite/networkSpecFiles/kafka_couchdb_tls.yaml -k "$KUBECONFIG"
  res=$?
  checkResult $res "failed to launch the network"
  until [ "$(kubectl get pods --field-selector=status.phase!=Running | wc -l)" == 0 ]; do
    pods=$(kubectl get pods --field-selector=status.phase!=Running | wc -l)
    sleep 30
    echo " ------> Waiting for $pods more pods to start"
  done
  # Copy channel config tx (workaround)
  cd "$GOPATH"/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen || exit
  ls
  mkdir -p ordererOrganizations
  cp -r connection-profile/*.* ../../../tools/PTE/CITest/CIConnProfiles/test-network/
  rm -rf ../../../tools/PTE/CITest/CIConnProfiles/test-network/config.yaml
  cp -r channel-artifacts/*.* ordererOrganizations/
  ls "$GOPATH"/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/ordererOrganizations
  cd -
}

# Stop Network
stopNw() {
  cd "$OperatorDir"/launcher || exit
  # provide networkspec 1 and kubeconfig 1 here
  go run launcher.go -i "$PTEDir"/CITest/k8s_testsuite/networkSpecFiles/kafka_couchdb_tls.yaml -k "$KUBECONFIG" -a down
  res=$?
  echo "res $res"
  checkResult $res "Failed to stop the network"
  until [ "$(kubectl get pods --field-selector=status.phase=Running | wc -l)" == 0 ]; do
    pods=$(kubectl get pods --field-selector=status.phase=Running | wc -l)
    echo " ------> Waiting for $pods more pods to stop"
    sleep 30
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
  sleep 30
  cd "$PTEDir/CITest/scripts"
  echo "-------> Create & Join Channel"
  export hfc_logging='{"debug":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 3 --chan0 0 --chantxpath "$Chantxpath" --chanprefix testorgschannel --norg 1 -c > "$PTEDir"/createChannel.log
  sleep 60
}

# install/instantiate chaincode: samplecc samplejs marbles02
installInstantiate() {
  cd "$PTEDir/CITest/scripts"
  # Install and Instantiate chaincode
  echo "-------> Install & Instantiate Chaincode"
  export hfc_logging='{"info":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 3 --chan0 0 --chantxpath "$Chantxpath" --chanprefix testorgschannel --norg 1 -a samplecc samplejs -i > "$PTEDir"/installInstantiate.log
  sleep 120
}

# Execute FAB-3833-2i test case wtih samplecc chaincode
samplecc_go_2chan() {
  # Execute Test Case
  cd "$PTEDir"/CITest/scripts
  echo "-------> Execute Invoke"
  export hfc_logging='{"info":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 1 --chanprefix testorgschannel --chantxpath "$Chantxpath" -a samplecc --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move > "$PTEDir"/samplecc_go_2chan_i.log
  sleep 60
  cp -r "$PTEDir"/pteReport.txt samplecc_go_2chan_i_pteReport.txt
  node get_pteReport.js samplecc_go_2chan_i_pteReport.txt
  rm -rf "$PTEDir"/pteReport.txt
  echo "-------> Execute Query"
  export hfc_logging='{"info":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 1 --chanprefix testorgschannel --chantxpath "$Chantxpath" -a samplecc --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t query > "$PTEDir"/samplecc_go_2chan_q.log
  sleep 60
  cp -r "$PTEDir"/pteReport.txt samplecc_go_2chan_q_pteReport.txt
  # Convert Test Report into Aggregate summary
  node get_pteReport.js samplecc_go_2chan_q_pteReport.txt
  # remove PTE Report
  rm -rf "$PTEDir"/pteReport.txt
}

# Execute FAB-4038-2i test case wtih samplejs chaincode
samplejs_node_2chan() {
  cd "$PTEDir"/CITest/scripts
  echo "-------> Execute Invoke"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --norg 1 --chantxpath "$Chantxpath" --chanprefix testorgschannel -a samplejs --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move > "$PTEDir"/samplejs_node_2chan_i.log
    cp -r "$PTEDir"/pteReport.txt samplejs_node_2chan_i_pteReport.txt
  # Convert Test Report into Aggregate summary
  node get_pteReport.js samplejs_node_2chan_i_pteReport.txt
  # remove PTE Report
  rm -rf "$PTEDir"/pteReport.txt
  sleep 60
  echo "-------> Execute Query"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --norg 1 --chantxpath "$Chantxpath" --chanprefix testorgschannel -a samplejs --freq 10 --nreq 10  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t query > "$PTEDir"/samplejs_node_2chan_q.log
  cp -r "$PTEDir"/pteReport.txt samplejs_node_2chan_q_pteReport.txt
  # Convert Test Report into Aggregate summary
  node get_pteReport.js samplejs_node_2chan_q_pteReport.txt
  # remove PTE Report
  rm -rf "$PTEDir"/pteReport.txt
}

case "$action" in
  up)
    echo "Start Network"
    startNw
    ;;
  down)
    echo "Down Network"
    stopNw
    ;;
esac

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
fi
