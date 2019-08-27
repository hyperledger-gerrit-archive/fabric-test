#!/bin/bash -e
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
#

while getopts ":f:a:t:p:ci" opt;
  do
    case $opt in
      a) # action with up/down
        action="${OPTARG}"
        ;;
      t)  # Execute test case
        testCase="${OPTARG}"
        ;;
      p)  # install npm node modules
        preReq="${OPTARG}"
        ;;
      c)  # Create channel & join
        createc="y"
        ;;
      i)  # Install & Instantiate
        insta="y"
        ;;
      f)  # network spec file
        nws="${OPTARG}"
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

startNw() {
  # Create fabric network on k8s cluster
  cd "$OperatorDir"/launcher || exit 1
  # export kubeconfig file to KUBECONFIG
  go run launcher.go -i "$PTEDir"/CITest/k8s_testsuite/networkSpecFiles/$1 -k "$KUBECONFIG"
  cd "$GOPATH"/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen || exit 1
  ls
  mkdir -p ordererOrganizations
  # Delete default connection profile to avoid reading this file for k8s tests
  rm -rf ../../../tools/PTE/CITest/CIConnProfiles/test-network/config.yaml
  # Copy connection profile to sub directories under PTE (PTE script appends connection profile to PTE directory)
  cp -r connection-profile/*.* ../../../tools/PTE/CITest/CIConnProfiles/test-network/
  # Workaround to avoid GOPATH adding in connection profile
  for conn in ../../../tools/PTE/CITest/CIConnProfiles/test-network/*.yaml; do
    { echo 'gopath: GOPATH'; cat "$conn"; } >"$conn.tmp" && mv "$conn.tmp" "$conn"
  done
  # Copy channel-artifacts to satisfy the default path of genconfig
  cp -r channel-artifacts/*.* ordererOrganizations/
  ls "$GOPATH"/src/github.com/hyperledger/fabric-test/fabric/internal/cryptogen/ordererOrganizations
  cd -
}

# Stop Network
stopNw() {
  cd "$OperatorDir"/launcher || exit 1
  # provide networkspec 1 and kubeconfig 1 here
  go run launcher.go -i "$PTEDir"/CITest/k8s_testsuite/networkSpecFiles/$1 -k "$KUBECONFIG" -a down
  cd -
}

# install npm node modules
npmInstall() {
  cd "$PTEDir" || exit 1
  npm install
}

# create/join channel
createJoinChannel() {
  sleep 30
  cd "$PTEDir/CITest/scripts" || exit 1
  echo "-------> Create & Join Channel"
  export hfc_logging='{"debug":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 3 --chan0 0 --chantxpath "$Chantxpath" --chanprefix testorgschannel --norg 2 -c > "$PTEDir"/createChannel.log
  sleep 60
}

# install/instantiate chaincode: samplecc samplejs marbles02
installInstantiate() {
  cd "$PTEDir/CITest/scripts" || exit 1
  # Install and Instantiate chaincode
  echo "-------> Install & Instantiate Chaincode"
  export hfc_logging='{"debug":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 3 --chan0 0 --chantxpath "$Chantxpath" --chanprefix testorgschannel --norg 2 -a sample_cc sample_js -i > "$PTEDir"/installInstantiate.log
  sleep 120
}

# Execute samplecc(go) chaincode 2 channel with 2 threads send 4000 tx's to OrgAnchors
samplecc_go_2chan() {
  # Execute Test Case
  cd "$PTEDir"/CITest/scripts || exit 1
  echo "-------> Execute Invoke"
  export hfc_logging='{"debug":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 2 --chanprefix testorgschannel --chantxpath "$Chantxpath" -a sample_cc --freq 10 --nreq 1000  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move > "$PTEDir"/samplecc_go_2chan_i.log
  sleep 60
  cp -r "$PTEDir"/pteReport.txt samplecc_go_2chan_i_pteReport.txt
  node get_pteReport.js samplecc_go_2chan_i_pteReport.txt
  rm -rf "$PTEDir"/pteReport.txt
  echo "-------> Execute Query"
  export hfc_logging='{"debug":"console"}'
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 2 --chanprefix testorgschannel --chantxpath "$Chantxpath" -a sample_cc --freq 10 --nreq 1000  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t query > "$PTEDir"/samplecc_go_2chan_q.log
  sleep 60
  cp -r "$PTEDir"/pteReport.txt samplecc_go_2chan_q_pteReport.txt
  # Convert Test Report into Aggregate summary
  node get_pteReport.js samplecc_go_2chan_q_pteReport.txt
  # remove PTE Report
  rm -rf "$PTEDir"/pteReport.txt
}

# Execute samplejs(node) chaincode 2 channels with 2 threads send 4000 tx's to OrgAnchors
samplejs_node_2chan() {
  cd "$PTEDir"/CITest/scripts || exit 1
  echo "-------> Execute Invoke"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 2 --chantxpath "$Chantxpath" --chanprefix testorgschannel -a sample_js --freq 10 --nreq 1000  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move > "$PTEDir"/samplejs_node_2chan_i.log
    cp -r "$PTEDir"/pteReport.txt samplejs_node_2chan_i_pteReport.txt
  # Convert Test Report into Aggregate summary
  node get_pteReport.js samplejs_node_2chan_i_pteReport.txt
  # remove PTE Report
  rm -rf "$PTEDir"/pteReport.txt
  sleep 60
  echo "-------> Execute Query"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 2 --chantxpath "$Chantxpath" --chanprefix testorgschannel -a sample_js --freq 10 --nreq 1000  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t query > "$PTEDir"/samplejs_node_2chan_q.log
  cp -r "$PTEDir"/pteReport.txt samplejs_node_2chan_q_pteReport.txt
  # Convert Test Report into Aggregate summary
  node get_pteReport.js samplejs_node_2chan_q_pteReport.txt
  # remove PTE Report
  rm -rf "$PTEDir"/pteReport.txt
}

# Execute samplecc(go) chaincode 2 channel with 2 threads send 4000 tx's to OrgAnchors - 12hr lognrun
samplecc_go_12hr() {
  # Execute Test Case
  cd "$PTEDir"/CITest/scripts || exit 1
  echo "-------> Execute Invoke"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 2 --chanprefix testorgschannel --chantxpath "$Chantxpath" -a sample_cc --freq 10 --rundur 43200 --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t move > "$PTEDir"/samplecc_go_2chan_12hr_i.log
  sleep 60
  cp -r "$PTEDir"/pteReport.txt samplecc_go_2chan_12hr_i_pteReport.txt
  node get_pteReport.js samplecc_go_2chan_12hr_i_pteReport.txt
  rm -rf "$PTEDir"/pteReport.txt
  echo "-------> Execute Query"
  ./gen_cfgInputs.sh -d "$ConnProfile" --nchan 2 --chan0 0 --norg 2 --chanprefix testorgschannel --chantxpath "$Chantxpath" -a sample_cc --freq 10 --nreq 1000  --nproc 2 --keystart 100 --targetpeers ORGANCHOR -t query > "$PTEDir"/samplecc_go_2chan_12hr_q.log
  sleep 60
  cp -r "$PTEDir"/pteReport.txt samplecc_go_2chan_12hr_q_pteReport.txt
  # Convert Test Report into Aggregate summary
  node get_pteReport.js samplecc_go_2chan_12hr_q_pteReport.txt
  # remove PTE Report
  rm -rf "$PTEDir"/pteReport.txt
}

# Install npm
if [ "$preReq" == "y" ]; then
  npmInstall
fi
case "$action" in
  up)
    echo "Start Network"
    startNw $nws
    exit
    ;;
  down)
    echo "Down Network"
    stopNw $nws
    exit
    ;;
esac
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
