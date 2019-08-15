// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package k8s

import (
	"fmt"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

//CreateMSPConfigMaps - create msp using configmap for peers, orderers and CA
func (k K8s) CreateMSPConfigMaps(input networkspec.Config, kubeConfigPath string) error {

	var err error
	k.KubeConfigPath = kubeConfigPath
	for i := 0; i < len(input.OrdererOrganizations); i++ {
		organization := input.OrdererOrganizations[i]
		err := k.createCertsConfigmap(organization.NumOrderers, organization.NumCA, "orderer", organization.Name, input)
		if err != nil {
			return err
		}
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		organization := input.PeerOrganizations[i]
		err = k.createCertsConfigmap(organization.NumPeers, organization.NumCA, "peer", organization.Name, input)
		if err != nil {
			return err
		}
	}
	return nil
}

func (k K8s) createCertsConfigmap(numComponents int, numCA int, componentType, orgName string, input networkspec.Config) error {

	var path, componentName, k8sComponentName string
	var err error
	var inputPaths []string
	cryptoConfigPath := utils.CryptoConfigDir(input.ArtifactsLocation)
	for j := 0; j < numComponents; j++ {
		componentName = fmt.Sprintf("%s%d-%s", componentType, j, orgName)
		path = utils.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/%ss/%s.%s", componentType, orgName, componentType, componentName, orgName))
		inputPaths = []string{fmt.Sprintf("admincerts=%s/msp/admincerts/Admin@%s-cert.pem", path, orgName),
			fmt.Sprintf("cacerts=%s/msp/cacerts/ca.%s-cert.pem", path, orgName),
			fmt.Sprintf("signcerts=%s/msp/signcerts/%s.%s-cert.pem", path, componentName, orgName),
			fmt.Sprintf("keystore=%s/msp/keystore/priv_sk", path),
			fmt.Sprintf("tlscacerts=%s/msp/tlscacerts/tlsca.%s-cert.pem", path, orgName)}

		// Creating msp configmap for components
		k8sComponentName = fmt.Sprintf("%s-msp", componentName)
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "configmap")
		if err != nil {
			logger.INFO("Failed to create msp configmap for ", componentName)
			return err
		}
		k8sComponentName = fmt.Sprintf("%s-tls", componentName)
		inputPaths = []string{fmt.Sprintf("%s/tls/", path)}
		// Creating tls configmap for components
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "configmap")
		if err != nil {
			logger.INFO("Failed to create tls configmap for ", componentName)
			return err
		}
	}

	// Calling createCaCertsConfigmap to create ca certs configmap
	if numCA > 0 {
		k8sComponentName = fmt.Sprintf("%s-ca", orgName)
		caPath := utils.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s", componentType, orgName))
		inputPaths = []string{fmt.Sprintf("%s/ca/", caPath), fmt.Sprintf("%s/tlsca/", caPath)}
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "configmap")
		if err != nil {
			logger.INFO("Failed to create ca configmap for ", componentName)
			return err
		}
	}

	if input.TLS == "mutual" {
		k8sComponentName = fmt.Sprintf("%s-clientrootca-secret", orgName)
		path = utils.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/ca/ca.%s-cert.pem", componentType, orgName, orgName))
		err = k.createConfigmapsNSecrets(inputPaths, k8sComponentName, "secret")
		if err != nil {
			logger.INFO("Failed to create client root CA secret for ", componentName)
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
