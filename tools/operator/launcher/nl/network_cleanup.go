// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"os"
	"path/filepath"

	Client "github.com/hyperledger/fabric-test/tools/operator/client"
	helper "github.com/hyperledger/fabric-test/tools/operator/launcher/helper"
)

//NetworkCleanUp - to clean up the network
func NetworkCleanUp(networkSpec helper.Config, kubeConfigPath string) error {

	numOrdererOrganizations := len(networkSpec.OrdererOrganizations)
	if networkSpec.Orderer.OrdererType == "solo" || networkSpec.Orderer.OrdererType == "kafka" {
		numOrdererOrganizations = 1
	}
	for i := 0; i < numOrdererOrganizations; i++ {
		ordererOrg := networkSpec.OrdererOrganizations[i]
		numOrderers := ordererOrg.NumOrderers
		if networkSpec.Orderer.OrdererType == "solo" {
			numOrderers = 1
		}
		deleteSecrets(numOrderers, "orderer", networkSpec.OrdererOrganizations[i].Name, kubeConfigPath, networkSpec.TLS)
		deleteSecrets(networkSpec.OrdererOrganizations[i].NumCA, "ca", networkSpec.OrdererOrganizations[i].Name, kubeConfigPath, networkSpec.TLS)
	}

	for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
		deleteSecrets(networkSpec.PeerOrganizations[i].NumPeers, "peer", networkSpec.PeerOrganizations[i].Name, kubeConfigPath, networkSpec.TLS)
		deleteSecrets(networkSpec.PeerOrganizations[i].NumCA, "ca", networkSpec.PeerOrganizations[i].Name, kubeConfigPath, networkSpec.TLS)
	}
	err := Client.ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", "genesisblock")
	err = Client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./configFiles/fabric-k8s-pods.yaml")
	if networkSpec.K8s.DataPersistence == "local" {
		err = Client.ExecuteK8sCommand(kubeConfigPath, "apply", "-f", "./scripts/alpine.yaml")
	}
	err = Client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./configFiles/k8s-service.yaml")
	err = Client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./configFiles/fabric-pvc.yaml")
	err = Client.ExecuteK8sCommand(kubeConfigPath, "delete", "configmaps", "certsparser")
	if err != nil {
		fmt.Println(err.Error())
	}

	err = os.RemoveAll("configFiles")
	err = os.RemoveAll("../templates/input.yaml")
	path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
	err = os.RemoveAll(path)
	path = filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
	err = os.RemoveAll(path)
	path = filepath.Join(networkSpec.ArtifactsLocation, "connection-profile")
	err = os.RemoveAll(path)
	if networkSpec.K8s.DataPersistence == "local" {
		err = Client.ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./scripts/alpine.yaml")
	}
	if err != nil {
		return err
	}
	return nil
}

func deleteSecrets(numComponents int, componentType, orgName, kubeConfigPath, tls string) {

	for j := 0; j < numComponents; j++ {
		componentName := fmt.Sprintf("%v%v-%v", componentType, j, orgName)
		err := Client.ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", componentName)
		if err != nil {
			fmt.Println(err.Error())
		}
	}
	if (componentType == "peer" || componentType == "orderer") && tls == "mutual" {
		err := Client.ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", fmt.Sprintf("%v-clientrootca-secret", orgName))
		if err != nil {
			fmt.Println(err.Error())
		}
	}
}
