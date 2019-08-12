// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"log"
	"path/filepath"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

//CreateMspSecret - to create msp secret for peers, orderers and CA
func CreateMspSecret(input networkspec.Config, kubeConfigPath string) {

	numOrdererOrganizations := len(input.OrdererOrganizations)
	if input.Orderer.OrdererType == "solo" || input.Orderer.OrdererType == "kafka" {
		numOrdererOrganizations = 1
	}
	for i := 0; i < numOrdererOrganizations; i++ {
		organization := input.OrdererOrganizations[i]
		numOrderers := organization.NumOrderers
		if input.Orderer.OrdererType == "solo" {
			numOrderers = 1
		}
		launchMspSecret(numOrderers, false, "orderer", organization.Name, kubeConfigPath, input)
		launchMspSecret(organization.NumCA, true, "orderer", organization.Name, kubeConfigPath, input)
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		organization := input.PeerOrganizations[i]
		launchMspSecret(organization.NumPeers, false, "peer", organization.Name, kubeConfigPath, input)
		launchMspSecret(organization.NumCA, true, "peer", organization.Name, kubeConfigPath, input)
	}
}

func launchMspSecret(numComponents int, isCA bool, componentType, orgName, kubeConfigPath string, input networkspec.Config) {

	var path, caPath, componentName string
	for j := 0; j < numComponents; j++ {
		componentName = fmt.Sprintf("ca%v-%v", j, orgName)
		if isCA != true {
			componentName = fmt.Sprintf("%v%v-%v", componentType, j, orgName)
			path = filepath.Join(input.ArtifactsLocation, fmt.Sprintf("crypto-config/%vOrganizations/%v/%vs/%v.%v", componentType, orgName, componentType, componentName, orgName))
		}
		caPath = filepath.Join(input.ArtifactsLocation, fmt.Sprintf("crypto-config/%vOrganizations/%v", componentType, orgName))
		//err := createMspJSON(input, path, caPath, componentName, kubeConfigPath)
		//if err != nil {
		//	log.Fatalf("Failed to create msp secret for %v; err: %v", componentName, err)
		//}
	}
	if isCA == false && input.TLS == "mutual" {
		err := client.ExecuteK8sCommand(kubeConfigPath, "create", "secret", "generic", fmt.Sprintf("%v-clientrootca-secret", orgName), fmt.Sprintf("--from-file=%v/crypto-config/%vOrganizations/%v/ca/ca.%v-cert.pem", input.ArtifactsLocation, componentType, orgName, orgName))
		if err != nil {
			log.Fatalf("Failed to create msp secret with client root CA for %v; err: %v", componentName, err)
		}
	}
}
