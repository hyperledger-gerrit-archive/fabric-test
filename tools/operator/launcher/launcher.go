// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"
	"io/ioutil"
	"log"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/connectionprofile"
	"github.com/hyperledger/fabric-test/tools/operator/health"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

type Environment struct{
	Env string
	FilePath string
}

var networkSpecPath = flag.String("i", "", "Network spec input file path")
var kubeConfigPath = flag.String("k", "", "Kube config file path")
var action = flag.String("a", "up", "Set action(up or down)")

func validateArguments(networkSpecPath *string, kubeConfigPath *string) {

	if *networkSpecPath == "" {
		log.Fatalln("Input file not provided")
	} else if *kubeConfigPath == "" {
		log.Println("Kube config file not provided, proceeding with local environment")
	}
}

func doAction(action string, input networkspec.Config) {

	configFilesPath := utils.ConfigFilesDir()
	switch action {
	case "up":
		err := nl.GenerateConfigurationFiles()
		if err != nil {
			log.Fatalf("Failed to generate yaml files; err: %s", err)
		}
		err = nl.GenerateCryptoCerts(input)
		if err != nil {
			log.Fatalf("Failed to generate certificates; err: %s", err)
		}

		if kubeConfigPath != "" {
			err = nl.CreateMSPConfigMaps(input, kubeConfigPath)
			if err != nil {
				log.Fatalf("Failed to create config maps; err: %s", err)
			}
		}

		err = nl.GenerateGenesisBlock(input)
		if err != nil {
			log.Fatalf("Failed to create orderer genesis block; err: %s", err)
		}

		err = client.GenerateChannelTransaction(input, configFilesPath)
		if err != nil {
			log.Fatalf("Failed to create channel transactions; err: %s", err)
		}

		if kubeConfigPath != "" {
			err = nl.LaunchK8sComponents(kubeConfigPath, input.K8s.DataPersistence)
			if err != nil {
				log.Fatalf("Failed to launch k8s components; err: %s", err)
			}
		} else {
			err = nl.LaunchLocalNetwork()
			if err != nil {
				log.Fatalf("Failed to launch docker containers; err: %s", err)
			}
		}

		err = health.VerifyContainersAreRunning(kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to check container status; err: %s", err)
		}

		err = health.CheckComponentsHealth("", kubeConfigPath, input)
		if err != nil {
			log.Fatalf("Failed to check health of fabric components; err: %s", err)
		}

		err = connectionprofile.GenerateConnectionProfiles(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to create connection profile; err: %s", err)
		}
		log.Println("Network is up and running")

	case "down":
		err := nl.NetworkCleanUp(input, kubeConfigPath)
		if err != nil {
			log.Fatalf("Failed to clean up the network; err: %s", err)
		}

	default:
		log.Fatalf("Incorrect action (%s). Use up or down for action", action)
	}
}

func (e Environment) network(){
	switch e.Env{
	case "docker":
		
	case "k8s":
	default:
	}
}


func checkConsensusType(input networkspec.Config) {

	ordererType := input.Orderer.OrdererType
	if ordererType == "solo" {
		if !(len(input.OrdererOrganizations) == 1 && input.OrdererOrganizations[0].NumOrderers == 1) {
			log.Fatalln("Consensus type solo should have only one orderer organization and one orderer")
		}
	} else if ordererType == "kafka" {
		if len(input.OrdererOrganizations) != 1 {
			log.Fatalln("Consensus type kafka should have only one orderer organization")
		}
	}
}

func main() {

	flag.Parse()
	err := utils.DownloadYtt()
	if err != nil {
		log.Fatalln(err)
	}
	validateArguments(networkSpecPath, kubeConfigPath)
	contents, err := ioutil.ReadFile(*networkSpecPath)
	if err != nil {
		log.Fatalf("In-correct input file path; err: %s", err)
	}
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := utils.JoinPath(utils.TemplatesDir(), "input.yaml")
	ioutil.WriteFile(inputPath, contents, 0644)
	input, err := nl.GetConfigData(inputPath)
	if err != nil {
		log.Fatalln(err)
	}
	checkConsensusType(input)
	doAction(*action, input, *kubeConfigPath)
}