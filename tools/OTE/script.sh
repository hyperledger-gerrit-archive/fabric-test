#!/bin/bash -e
echo "#########################################"
echo "#                                       #"
echo "#            WELCOME TO OTE             #"
echo "#                                       #"
echo "#########################################"

echo "[fabric-test/tools/OTE/script.sh] Creating Channels: $numChannels"
for (( i=1; i<=${numChannels}; i++ ))
do
       sleep 2
       export CORE_PEER_LOCALMSPID="OrdererOrg"
       export CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/artifacts/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
       export CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/fabric/artifacts/ordererOrganizations/example.com/users/Admin@example.com/msp

       peer channel create -o orderer0.example.com:5005 -c testorgschannel$i -f /etc/hyperledger/fabric/artifacts/ordererOrganizations/testorgschannel$i.tx --tls --cafile /etc/hyperledger/fabric/artifacts/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -t 60s
done
go build
sleep 40
go test -run $TESTCASE -timeout=90m
mv ote-*.log ote.log
