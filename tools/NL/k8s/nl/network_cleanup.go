// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"os"
)

//NetworkCleanUp - to clean up the network
func NetworkCleanUp(networkSpec Config, kubeConfigPath string) error {

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
		deleteSecrets(numOrderers, "orderer", networkSpec.OrdererOrganizations[i].Name, kubeConfigPath)
		deleteSecrets(networkSpec.OrdererOrganizations[i].NumCA, "ca", networkSpec.OrdererOrganizations[i].Name, kubeConfigPath)
	}

	for i := 0; i < len(networkSpec.PeerOrganizations); i++ {
		deleteSecrets(networkSpec.PeerOrganizations[i].NumPeers, "peer", networkSpec.PeerOrganizations[i].Name, kubeConfigPath)
		deleteSecrets(networkSpec.PeerOrganizations[i].NumCA, "ca", networkSpec.PeerOrganizations[i].Name, kubeConfigPath)
	}
	err := ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", "genesisblock")
	err = ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./configFiles/fabric-k8s-pods.yaml")
	if networkSpec.K8s.DataPersistence == "local" {
		err = ExecuteK8sCommand(kubeConfigPath, "apply", "-f", "./scripts/alpine.yaml")
	}
	err = ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./configFiles/k8s-service.yaml")
	err = ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./configFiles/fabric-pvc.yaml")
	err = ExecuteK8sCommand(kubeConfigPath, "delete", "configmaps", "certsparser")
	if err != nil {
		fmt.Println(err.Error())
	}

	err = os.RemoveAll("configFiles")
	err = os.RemoveAll("templates/input.yaml")
	err = os.RemoveAll(networkSpec.ArtifactsLocation)
	if networkSpec.K8s.DataPersistence == "local" {
		err = ExecuteK8sCommand(kubeConfigPath, "delete", "-f", "./scripts/alpine.yaml")
	}
	if err != nil {
		return err
	}
	return nil
}

func deleteSecrets(numComponents int, componentType, orgName, kubeConfigPath string) {

	for j := 0; j < numComponents; j++ {
		componentName := fmt.Sprintf("%v%v-%v", componentType, j, orgName)
		err := ExecuteK8sCommand(kubeConfigPath, "delete", "secrets", componentName)
		if err != nil {
			fmt.Println(err.Error())
		}
	}
}