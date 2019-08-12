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

//Msp - create msp using configmap for peers, orderers and CA
func Msp(input networkspec.Config, kubeConfigPath string) {

	for i := 0; i < len(input.OrdererOrganizations); i++ {
		organization := input.OrdererOrganizations[i]
		createCertsConfigmap(organization.NumOrderers, organization.NumCA , "orderer", organization.Name, kubeConfigPath, input)
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		organization := input.PeerOrganizations[i]
		createCertsConfigmap(organization.NumPeers, organization.NumCA, "peer", organization.Name, kubeConfigPath, input)
	}
}

func createCertsConfigmap(numComponents int, numCA int, componentType, orgName, kubeConfigPath string, input networkspec.Config) {

	var path, componentName string
	
	for j := 0; j < numComponents; j++ {
		componentName = fmt.Sprintf("%s%d-%s", componentType, j, orgName)
		path = filepath.Join(input.ArtifactsLocation, fmt.Sprintf("crypto-config/%sOrganizations/%s/%ss/%s.%s", componentType, orgName, componentType, componentName, orgName))
		
		// Creating msp configmap for components
		err := client.ExecuteK8sCommand(kubeConfigPath, "create", "configmap", fmt.Sprintf("%s-msp", componentName), fmt.Sprintf("--from-file=admincerts=%s/msp/admincerts/Admin@%s-cert.pem", path, orgName), fmt.Sprintf("--from-file=cacerts=%s/msp/cacerts/ca.%s-cert.pem", path, orgName), fmt.Sprintf("--from-file=signcerts=%s/msp/signcerts/%s.%s-cert.pem", path, componentName, orgName), fmt.Sprintf("--from-file=keystore=%s/msp/keystore/priv_sk", path), fmt.Sprintf("--from-file=tlscacerts=%s/msp/tlscacerts/tlsca.%s-cert.pem", path, orgName))
		if err != nil {
			log.Fatalf("Failed to create msp configmap for %s; err: %s", componentName, err)
		}
        
        // Creating tls configmap for components
		err = client.ExecuteK8sCommand(kubeConfigPath, "create", "configmap", fmt.Sprintf("%s-tls", componentName), fmt.Sprintf("--from-file=%s/tls/", path))
		if err != nil {
			log.Fatalf("Failed to create tls configmap for %s; err: %s", componentName, err)
		}
	}

	// Calling createCaCertsConfigmap to create ca certs configmap
	if numCA > 0 {
		createCaCertsConfigmap(componentType, orgName, kubeConfigPath, input)
	}
	
	if input.TLS == "mutual" {
		err := client.ExecuteK8sCommand(kubeConfigPath, "create", "secret", "generic", fmt.Sprintf("%s-clientrootca-secret", orgName), fmt.Sprintf("--from-file=%s/crypto-config/%sOrganizations/%s/ca/ca.%s-cert.pem", input.ArtifactsLocation, componentType, orgName, orgName))
		if err != nil {
			log.Fatalf("Failed to create secret for %s client root CA; err: %s", componentName, err)
		}
	}
}

func createCaCertsConfigmap(componentType, orgName, kubeConfigPath string, input networkspec.Config) {
	componentName := fmt.Sprintf("%s-ca", orgName)
	caPath := filepath.Join(input.ArtifactsLocation, fmt.Sprintf("crypto-config/%sOrganizations/%s", componentType, orgName))
	err := client.ExecuteK8sCommand(kubeConfigPath, "create", "configmap", fmt.Sprintf("%s", componentName), fmt.Sprintf("--from-file=%s/ca/", caPath), fmt.Sprintf("--from-file=%s/tlsca/", caPath))
	if err != nil {
		log.Fatalf("Failed to create ca configmap for %s; err: %s", componentName, err)
	}
}
