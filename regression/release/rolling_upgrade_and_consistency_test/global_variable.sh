#!/bin/bash

ORG1=1
ORG2=2

TIMEOUT="60"
ORDERER=localhost:7050
CHANNEL_AND_CHAINCODE_PVT='-C ch1 -n marbles_private'
CHANNEL_AND_CHAINCODE_PUB='-C ch1 -n marbles'

