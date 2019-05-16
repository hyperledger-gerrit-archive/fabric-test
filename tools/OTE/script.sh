#!/bin/bash
echo "#########################################"
echo "#                                       #"
echo "#            WELCOME TO OTE             #"
echo "#                                       #"
echo "#########################################"

echo "Creating Channels"
echo $numChannels
for (( i=1; i<=${numChannels}; i++ ))
do
       peer channel create -o orderer0.example.com:5005 -c testorgschannel$i -f /etc/hyperledger/fabric/artifacts/ordererOrganizations/testorgschannel$i.tx --tls --cafile /etc/hyperledger/fabric/artifacts/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -t 60s
done
 echo "PATH = $PATH"
 echo '$ which gcc'
 which gcc || echo 'warning: gcc not found in PATH'
 echo '$ go build'
go build
sleep 40
 echo "$ go test -run $TESTCASE"'
go test -run $TESTCASE -timeout=90m
mv ote-*.log ote.log
