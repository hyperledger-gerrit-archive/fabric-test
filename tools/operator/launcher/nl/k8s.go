// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"log"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/helper"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
)

type K8s struct {
	Action string
	Input  []string
}

func (k K8s) Args(kubeConfigPath string) []string {

	kubeConfigPath = fmt.Sprintf("--kubeconfig=%s", kubeConfigPath)
	args := []string{kubeConfigPath}
	if k.Action != ""{
		args = append(args, k.Action)
	}
	for i := 0; i < len(k.Input); i++ {
		switch k.Action {
		case "apply", "delete":
			args = append(args, []string{"-f", k.Input[i]}...)
		default:
			args = append(args, k.Input[i])
		}

	}
	return args
}

//LaunchK8sComponents - to launch the kubernates components
func LaunchK8sComponents(kubeConfigPath string, isDataPersistence string) error {
	k8sServicesFile := helper.ConfigFilePath("services")
	k8sPodsFile := helper.ConfigFilePath("pods")
	inputPaths := []string{k8sServicesFile, k8sPodsFile}
	if isDataPersistence == "true" {
		k8sPvcFile := helper.ConfigFilePath("pvc")
		inputPaths = append(inputPaths, k8sPvcFile)
	}
	k8s := K8s{Action: "apply", Input: inputPaths}
	_, err := client.ExecuteK8sCommand(k8s.Args(kubeConfigPath), true)
	if err != nil {
		log.Println("Failed to launch the fabric k8s components")
		return err
	}
	return nil
}

//DownK8sComponents - To tear down the kubernates network
func DownK8sComponents(kubeConfigPath string, input networkspec.Config) error {

	var err error
	numOrdererOrganizations := len(input.OrdererOrganizations)
	for i := 0; i < numOrdererOrganizations; i++ {
		ordererOrg := input.OrdererOrganizations[i]
		err = deleteSecrets(ordererOrg.NumOrderers, "orderer", ordererOrg.Name, kubeConfigPath, input.TLS)
		if err != nil{
			log.Printf("Failed to delete orderer secrets in %s", ordererOrg.Name)
		}
		err = deleteSecrets(ordererOrg.NumCA, "ca", ordererOrg.Name, kubeConfigPath, input.TLS)
		if err != nil{
			log.Printf("Failed to delete ca secrets in %s", ordererOrg.Name)
		}
	}

	for i := 0; i < len(input.PeerOrganizations); i++ {
		peerOrg := input.PeerOrganizations[i]
		deleteSecrets(peerOrg.NumPeers, "peer", peerOrg.Name, kubeConfigPath, input.TLS)
		if err != nil{
			log.Printf("Failed to delete peer secrets in %s", peerOrg.Name)
		}
		deleteSecrets(peerOrg.NumCA, "ca", peerOrg.Name, kubeConfigPath, input.TLS)
		if err != nil{
			log.Printf("Failed to delete ca secrets in %s", peerOrg.Name)
		}
	}
	k8sServicesFile := helper.ConfigFilePath("services")
	k8sPodsFile := helper.ConfigFilePath("pods")

	var inputPaths []string
	var k8s K8s
	if input.K8s.DataPersistence == "local" {
		inputPaths = []string{dataPersistenceFilePath(input)}
		k8s = K8s{Action: "apply", Input: inputPaths}
		_, err = client.ExecuteK8sCommand(k8s.Args(kubeConfigPath), true)
		if err != nil {
			log.Println("Failed to launch k8s pod")
		}
	}
	inputPaths = []string{k8sServicesFile, k8sPodsFile}
	if input.K8s.DataPersistence == "true" || input.K8s.DataPersistence == "local" {
		inputPaths = append(inputPaths, dataPersistenceFilePath(input))
	}

	k8s = K8s{Action: "delete", Input: inputPaths}
	_, err = client.ExecuteK8sCommand(k8s.Args(kubeConfigPath), true)
	if err != nil {
		log.Println("Failed to down k8s pods")
	}

	err = k8sType("delete", "secrets", "genesisblock", kubeConfigPath)
	if err != nil {
		log.Println("Failed to delete secret genesisblock")
	}

	err = k8sType("delete", "configmaps", "certsparser", kubeConfigPath)
	if err != nil {
		log.Println("Failed to delete configmaps certsparser")
	}
	return nil
}

func dataPersistenceFilePath(input networkspec.Config) string {
	var path string
	currDir, err := helper.GetCurrentDir()
	if err != nil {
		log.Println("Failed to get the current working directory")
	}
	switch input.K8s.DataPersistence {
	case "local":
		path = helper.JoinPath(currDir, "alpine.yaml")
	default:
		path = helper.ConfigFilePath("pvc")
	}
	return path
}

func k8sType(action, k8stype, name, kubeConfigPath string) error{
	var err error
	args := []string{action, k8stype, name}
	k8s := K8s{Action: "", Input: args}
	_, err = client.ExecuteK8sCommand(k8s.Args(kubeConfigPath), true)
	if err != nil {
		return err
	}
	return err
}

func deleteSecrets(numComponents int, componentType, orgName, kubeConfigPath, tls string) error{

	var componentsList []string
	if (componentType == "peer" || componentType == "orderer") && tls == "mutual" {
		componentsList = append(componentsList, fmt.Sprintf("%s-clientrootca-secret", orgName))
	}
	for j := 0; j < numComponents; j++ {
		componentsList = append(componentsList, fmt.Sprintf("%s%d-%s", componentType, j, orgName))
	}
	input := []string{"delete", "secrets"}
	input = append(input, componentsList...)
	k8s := K8s{Action: "", Input: input}
	_, err := client.ExecuteK8sCommand(k8s.Args(kubeConfigPath), true)
	if err != nil {
		return err
	}
	return nil
}
