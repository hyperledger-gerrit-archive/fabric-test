// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"
	"io/ioutil"
	"log"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/helper"
	"github.com/hyperledger/fabric-test/tools/operator/connectionprofile"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

var networkSpecPath = flag.String("i", "", "Network spec input file path")
var kubeConfigPath = flag.String("k", "", "Kube config file path")
var action = flag.String("a", "up", "Set action(up or down)")

func validateArguments(networkSpecPath *string, kubeConfigPath *string) {

	if *networkSpecPath == "" {
		log.Fatalf("Input file not provided")
	} else if *kubeConfigPath == "" {
		log.Printf("Kube config file not provided, proceeding with local environment")
	}
}

func doAction(action string, input networkspec.Config, kubeConfigPath string) {

	switch action {
	case "up":
		err := nl.GenerateConfigurationFiles(kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to generate yaml files; err = %s", err)
		}

		err = nl.GenerateCryptoCerts(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to generate certificates; err = %s", err)
		}

		if kubeConfigPath != "" {
			err = nl.CreateMspSecret(input, kubeConfigPath)
			if err != nil {
				log.Fatal(err)
			}
		}

		err = nl.GenerateGenesisBlock(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create orderer genesis block; err = %s", err)
		}

		err = client.GenerateChannelTransaction(input, []string{}, "./../configFiles")
		if err != nil {
			log.Fatalf("Failed to create channel transactions; err = %s", err)
		}

		if kubeConfigPath != "" {
			err = nl.LaunchK8sComponents(kubeConfigPath, input.K8s.DataPersistence)
			if err != nil {
				log.Fatalf("Failed to launch k8s components; err = %s", err)
			}
		} else {
			err = nl.LaunchLocalNetwork()
			if err != nil {
				log.Fatalf("Failed to launch k8s components; err = %s", err)
			}
		}

		err = client.CheckContainersState(kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to check container status; err = %s", err)
		}

		err = client.CheckComponentsHealth("", kubeConfigPath, input)
		if err != nil {
			log.Fatalf("Failed to check health of fabric components; err = %s", err)
		}

		err = connectionprofile.CreateConnectionProfile(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create connection profile; err = %s", err)
		}
		log.Printf("Network is up and running")

	case "down":
		err := nl.NetworkCleanUp(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to clean up the network:; err = %s", err)
		}

	default:
		log.Fatalf("Incorrect action (%s). Use up or down for action", action)
	}
}

func checkConsensusType(input networkspec.Config) {

	ordererType := input.Orderer.OrdererType
	if ordererType == "solo" {
		if !(len(input.OrdererOrganizations) == 1 && input.OrdererOrganizations[0].NumOrderers == 1) {
			log.Fatalf("Consensus type solo should have only one orderer organization and one orderer")
		}
	} else if ordererType == "kafka" {
		if len(input.OrdererOrganizations) != 1 {
			log.Fatalf("Consensus type kafka should have only one orderer organization")
		}
	}
}

func main() {

	flag.Parse()
	err := utils.DownloadYtt()
	if err != nil {
		log.Fatal(err)
	}
	validateArguments(networkSpecPath, kubeConfigPath)
	contents, err := ioutil.ReadFile(*networkSpecPath)
	if err != nil {
		log.Fatalf("In-correct input file path; err:%s", err)
	}
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := helper.JoinPath(helper.TemplatesDir(), "input.yaml")
	ioutil.WriteFile(inputPath, contents, 0644)
	input, err := nl.GetConfigData(inputPath)
	if err != nil {
		log.Fatal(err)
	}
	checkConsensusType(input)
	doAction(*action, input, *kubeConfigPath)
}
