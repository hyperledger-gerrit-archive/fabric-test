// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package k8s

import (
	"fmt"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
)

//CreateMSPConfigMaps - create msp using configmap for peers, orderers and CA
func (k K8s) CreateMSPConfigMaps(config networkspec.Config) error {

	var err error
	for i := 0; i < len(config.OrdererOrganizations); i++ {
		organization := config.OrdererOrganizations[i]
		err := k.createCertsConfigmap(organization.NumOrderers, organization.NumCA, "orderer", organization.Name, config)
		if err != nil {
			return err
		}
	}

	for i := 0; i < len(config.PeerOrganizations); i++ {
		organization := config.PeerOrganizations[i]
		err = k.createCertsConfigmap(organization.NumPeers, organization.NumCA, "peer", organization.Name, config)
		if err != nil {
			return err
		}
	}
	return nil
}

func (k K8s) createCertsConfigmap(numComponents int, numCA int, componentType, orgName string, config networkspec.Config) error {

	var fileLocation, componentName, k8sComponentName string
	var err error
	var inputPaths []string
	cryptoConfigPath := paths.CryptoConfigDir(config.ArtifactsLocation)
	for j := 0; j < numComponents; j++ {
		componentName = fmt.Sprintf("%s%d-%s", componentType, j, orgName)
		fileLocation = paths.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/%ss/%s.%s", componentType, orgName, componentType, componentName, orgName))
		inputPaths = []string{fmt.Sprintf("config=%s/../../msp/config.yaml", fileLocation),
			fmt.Sprintf("cacerts=%s/msp/cacerts/ca.%s-cert.pem", fileLocation, orgName),
			fmt.Sprintf("signcerts=%s/msp/signcerts/%s.%s-cert.pem", fileLocation, componentName, orgName),
			fmt.Sprintf("keystore=%s/msp/keystore/priv_sk", fileLocation),
			fmt.Sprintf("tlscacerts=%s/msp/tlscacerts/tlsca.%s-cert.pem", fileLocation, orgName)}

		// Creating msp configmap for components
		k8sComponentName = fmt.Sprintf("%s-msp", componentName)
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "configmap")
		if err != nil {
			logger.ERROR("Failed to create msp configmap for ", componentName)
			return err
		}
		k8sComponentName = fmt.Sprintf("%s-tls", componentName)
		inputPaths = []string{fmt.Sprintf("%s/tls/", fileLocation)}
		// Creating tls configmap for components
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "configmap")
		if err != nil {
			logger.ERROR("Failed to create tls configmap for ", componentName)
			return err
		}
	}

	adminCertPath := paths.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/%ss/%s.%s/msp/admincerts/", componentType, orgName, componentType, componentName, orgName))
	inputPaths = []string{fmt.Sprintf("%s", adminCertPath)}
	k8sComponentName = fmt.Sprintf("%s-admincerts", orgName)
	err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "configmap")
	if err != nil {
		logger.ERROR("Failed to create admincerts configmap for ", orgName)
		return err
	}

	// Calling createConfigmapsNSecrets to create ca certs configmap
	if numCA > 0 {
		k8sComponentName = fmt.Sprintf("%s-ca", orgName)
		caPath := paths.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s", componentType, orgName))
		inputPaths = []string{fmt.Sprintf("%s/ca/", caPath), fmt.Sprintf("%s/tlsca/", caPath)}
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "configmap")
		if err != nil {
			logger.ERROR("Failed to create ca configmap for ", componentName)
			return err
		}
	}

	if config.TLS == "mutual" {
		k8sComponentName = fmt.Sprintf("%s-clientrootca-secret", orgName)
		fileLocation = paths.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/ca/ca.%s-cert.pem", componentType, orgName, orgName))
		inputPaths = []string{fileLocation}
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "secret")
		if err != nil {
			logger.ERROR("Failed to create client root CA secret for ", componentName)
			return err
		}
	}
	return nil
}

func (k K8s) createConfigmapsNSecrets(inputPaths []string, componentName, k8sType string) error {

	k = K8s{Action: "create", Arguments: inputPaths, KubeConfigPath: k.KubeConfigPath}
	_, err := client.ExecuteK8sCommand(k.ConfigMapsNSecretsArgs(componentName, k8sType), true)
	if err != nil {
		return err
	}
	return nil
}
