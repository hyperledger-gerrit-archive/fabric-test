// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"

	Client "fabric-test/tools/operator/client"
	NL "fabric-test/tools/operator/launcher/nl"
	helper "fabric-test/tools/operator/networkspec"
	utils "fabric-test/tools/operator/utils"
)

func readArguments() (string, string, string) {

	networkSpecPath := flag.String("i", "", "Network spec input file path")
	kubeConfigPath := flag.String("k", "", "Kube config file path")
	action := flag.String("a", "up", "Set action(up or down)")
	flag.Parse()

	if fmt.Sprintf("%s", *kubeConfigPath) == "" {
		fmt.Printf("Kube config file not provided, proceeding with local environment")
	} else if fmt.Sprintf("%s", *networkSpecPath) == "" {
		log.Fatalf("Input file not provided")
	}

	return *networkSpecPath, *kubeConfigPath, *action
}

func doAction(action string, input helper.Config, kubeConfigPath string) {

	switch action {
	case "up":
		err := NL.GenerateConfigurationFiles(kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to generate yaml files; err = %v", err)
		}

		err = NL.GenerateCryptoCerts(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to generate certificates; err = %v", err)
		}

		if kubeConfigPath != "" {
			NL.CreateMspSecret(input, kubeConfigPath)
		}

		err = NL.GenerateGenesisBlock(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create orderer genesis block; err = %v", err)
		}

		err = Client.GenerateChannelTransaction(input, []string{}, "./../configFiles")
		if err != nil {
			log.Fatalf("Failed to create channel transactions; err = %v", err)
		}

		if kubeConfigPath != "" {
			err = NL.LaunchK8sComponents(kubeConfigPath, input.K8s.DataPersistence)
			if err != nil {
				log.Fatalf("Failed to launch k8s components; err = %v", err)
			}
		} else {
			err = NL.LaunchLocalNetwork()
			if err != nil {
				log.Fatalf("Failed to launch k8s components; err = %v", err)
			}
		}

		err = NL.CreateConnectionProfile(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to launch k8s components; err = %v", err)
		}

	case "down":
		err := NL.NetworkCleanUp(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to clean up the network:; err = %v", err)
		}

	default:
		log.Fatalf("Incorrect action (%v). Use up or down for action", action)
	}
}

func checkConsensusType(networkspec helper.Config) {

	ordererType := networkspec.Orderer.OrdererType
	if ordererType == "solo" {
		if !(len(networkspec.OrdererOrganizations) == 1 && networkspec.OrdererOrganizations[0].NumOrderers == 1) {
			log.Fatalf("Consensus type solo should have only one orderer organization and one orderer")
		}
	} else if ordererType == "kafka" {
		if len(networkspec.OrdererOrganizations) != 1 {
			log.Fatalf("Consensus type kafka should have only one orderer organization")
		}
	}
}

func main() {

	networkSpecPath, kubeConfigPath, action := readArguments()
	utils.DownloadYtt()
	contents, _ := ioutil.ReadFile(networkSpecPath)
	contents = append([]byte("#@data/values \n"), contents...)
	ioutil.WriteFile("./../templates/input.yaml", contents, 0644)
	inputPath := "./../templates/input.yaml"
	input := NL.GetConfigData(inputPath)
	checkConsensusType(input)
	doAction(action, input, kubeConfigPath)
}
