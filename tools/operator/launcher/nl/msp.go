// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"log"
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

//Msp - create msp using configmap for peers, orderers and CA
func Msp(input networkspec.Config, kubeConfigPath string) error {

	var err error
	for i := 0; i < len(input.OrdererOrganizations); i++ {
		organization := input.OrdererOrganizations[i]
		err := createCertsConfigmap(organization.NumOrderers, organization.NumCA, "orderer", organization.Name, kubeConfigPath, input)
		if err != nil {
			return err
		}
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		organization := input.PeerOrganizations[i]
		err = createCertsConfigmap(organization.NumPeers, organization.NumCA, "peer", organization.Name, kubeConfigPath, input)
		if err != nil {
			return err
		}
	}
	return nil
}

func createCertsConfigmap(numComponents int, numCA int, componentType, orgName, kubeConfigPath string, input networkspec.Config) error{

	var path, componentName string
	var err error
	var inputPaths []string
	cryptoConfigPath := utils.CryptoConfigDir(input.ArtifactsLocation)
	for j := 0; j < numComponents; j++ {
		componentName = fmt.Sprintf("%s%d-%s", componentType, j, orgName)
		path = utils.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/%ss/%s.%s", componentType, orgName, componentType, componentName, orgName))
		inputPaths = []string{fmt.Sprintf("admincerts=%s/msp/admincerts/Admin@%s-cert.pem", path, orgName),
							  fmt.Sprintf("cacerts=%s/msp/cacerts/ca.%s-cert.pem", path, orgName),
							  fmt.Sprintf("igncerts=%s/msp/signcerts/%s.%s-cert.pem", path, componentName, orgName),
							  fmt.Sprintf("keystore=%s/msp/keystore/priv_sk", path),
							  fmt.Sprintf("--from-file=tlscacerts=%s/msp/tlscacerts/tlsca.%s-cert.pem", path, orgName)}

		// Creating msp configmap for components
		err = createConfigmapsNSecrets(inputPaths, componentName, "configmap", kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create msp configmap for %s", componentName)
			return err
		}
		componentName = fmt.Sprintf("%s-tls", componentName)
		inputPaths = []string{fmt.Sprintf("%s/tls/", path)}
		// Creating tls configmap for components
		err = createConfigmapsNSecrets(inputPaths, componentName, "configmap", kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create tls configmap for %s", componentName)
			return err
		}
	}

	// Calling createCaCertsConfigmap to create ca certs configmap
	if numCA > 0 {
		componentName = fmt.Sprintf("%s-ca", componentName)
		caPath := utils.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s", componentType, orgName))
		inputPaths = []string{fmt.Sprintf("%s/tls/", caPath)}
		err = createConfigmapsNSecrets(inputPaths, componentName, "configmap", kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create ca configmap for %s", componentName)
			return err
		}
	}

	if input.TLS == "mutual" {
		componentName = fmt.Sprintf("%s-clientrootca-secret", orgName)
		path = utils.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/ca/ca.%s-cert.pem", componentType, orgName, orgName))
		err = createConfigmapsNSecrets(inputPaths, componentName, "secret", kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create secret for %s client root CA; err: %s", componentName, err)
			return err
		}
	}
	return nil
}

func createConfigmapsNSecrets(inputPaths []string, componentName, k8sType, kubeConfigPath string) error{
	
	var k8s K8s
	k8s = K8s{Action: "create", Input: inputPaths}
	_, err := client.ExecuteK8sCommand(k8s.ConfigMapsNSecretsArgs(kubeConfigPath, componentName, k8sType), true)
	if err != nil {
		return err
	}
	return nil
}
