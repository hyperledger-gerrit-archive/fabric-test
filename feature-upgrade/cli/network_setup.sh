#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#


UP_DOWN="$1"
CH_NAME="$2"
CLI_TIMEOUT="$3"
IF_COUCHDB="$4"

: ${CLI_TIMEOUT:="100"}

COMPOSE_FILE=docker-compose-e2e-template.yaml
COMPOSE_FILE_COUCH=docker-compose-couch.yaml
#COMPOSE_FILE=docker-compose-e2e.yaml

function printHelp () {
	echo "Usage: ./network_setup.sh <up|down|restart|upgrade> <\$channel-name> <\$cli_timeout> <couchdb>.\nThe arguments must be in order."
}

function validateArgs () {
	if [ -z "${UP_DOWN}" ]; then
		echo "Option up / down / restart not mentioned"
		printHelp
		exit 1
	fi
	if [ -z "${CH_NAME}" ]; then
		echo "setting to default channel 'mychannel'"
		CH_NAME=mychannel
	fi
}

function clearContainers () {
        CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS
        fi
}

function removeUnwantedImages() {
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
                echo "---- No images available for deletion ----"
        else
                docker rmi -f $DOCKER_IMAGE_IDS
        fi
}

function networkUp () {
    if [ -f "./crypto-config" ]; then
      echo "crypto-config directory already exists."
    else
      #Generate all the artifacts that includes org certs, orderer genesis block,
      # channel configuration transaction
      source generateArtifacts.sh $CH_NAME
    fi

    if [ "${IF_COUCHDB}" == "couchdb" ]; then
      CHANNEL_NAME=$CH_NAME TIMEOUT=$CLI_TIMEOUT docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH up -d 2>&1
    else
      CHANNEL_NAME=$CH_NAME TIMEOUT=$CLI_TIMEOUT docker-compose -f $COMPOSE_FILE up -d 2>&1
    fi
    if [ $? -ne 0 ]; then
	echo "ERROR !!!! Unable to pull the images "
	exit 1
    fi
    docker logs -f cli
}

function networkDown () {
    docker-compose -f $COMPOSE_FILE down

    #Cleanup the chaincode containers
    clearContainers

    #Cleanup images
    removeUnwantedImages

    # remove orderer block and other channel configuration transactions and certs
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config 
}

function upgradeNetwork () {
    echo "Launching network with v1.0.3"
    export IMAGE_TAG=x86_64-1.0.3
    export SCRIPT=script.sh
    networkUp

    sleep 10
    echo "Upgrading network to v1.1"
    docker rm -f orderer.example.com peer0.org1.example.com peer1.org1.example.com peer0.org2.example.com peer1.org2.example.com cli dev-peer0.org1.example.com-mycc-1.0 dev-peer0.org2.example.com-mycc-1.0 dev-peer1.org2.example.com-mycc-1.0
    docker rmi -f $(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
    export IMAGE_TAG=latest
    export SCRIPT=script_upgrade.sh
    docker-compose -f docker-compose-e2e.yaml up -d orderer.example.com peer0.org1.example.com peer1.org1.example.com peer0.org2.example.com peer1.org2.example.com cli
    docker logs -f cli
}

validateArgs

#Create the network using docker compose
if [ "${UP_DOWN}" == "up" ]; then
	networkUp
elif [ "${UP_DOWN}" == "down" ]; then ## Clear the network
	networkDown
elif [ "${UP_DOWN}" == "restart" ]; then ## Restart the network
	networkDown
	networkUp
elif [ "${UP_DOWN}" == "upgrade" ]; then ## Upgrade the network
        upgradeNetwork
else
	printHelp
	exit 1
fi
