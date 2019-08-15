// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"
	"fmt"
	"io/ioutil"

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
		utils.FatalLogs("Input file not provided", nil)
	} else if *kubeConfigPath == "" {
		utils.PrintLogs("Kube config file not provided, proceeding with local environment")
	}
}

func doAction(action string, input networkspec.Config) {

	configFilesPath := utils.ConfigFilesDir()
	switch action {
	case "up":
		err := nl.GenerateConfigurationFiles()
		if err != nil {
			utils.FatalLogs("Failed to generate yaml files", err)
		}
		err = nl.GenerateCryptoCerts(input)
		if err != nil {
			utils.FatalLogs("Failed to generate certificates", err)
		}

		if kubeConfigPath != "" {
			err = nl.Msp(input, kubeConfigPath)
			if err != nil {
				utils.FatalLogs("Failed to create msp", err)
			}
		}

		err = nl.GenerateGenesisBlock(input)
		if err != nil {
			utils.FatalLogs("Failed to create orderer genesis block", err)
		}

		err = client.GenerateChannelTransaction(input, configFilesPath)
		if err != nil {
			utils.FatalLogs("Failed to create channel transactions", err)
		}

		if kubeConfigPath != "" {
			err = nl.LaunchK8sComponents(kubeConfigPath, input.K8s.DataPersistence)
			if err != nil {
				utils.FatalLogs("Failed to launch k8s components", err)
			}
		} else {
			err = nl.LaunchLocalNetwork()
			if err != nil {
				utils.FatalLogs("Failed to launch docker containers", err)
			}
		}

		err = health.CheckContainersState(kubeConfigPath)
		if err != nil {
			utils.FatalLogs("Failed to check container status", err)
		}

		err = health.CheckComponentsHealth("", kubeConfigPath, input)
		if err != nil {
			utils.FatalLogs("Failed to check health of fabric components", err)
		}

		err = connectionprofile.GenerateConnectionProfiles(input, kubeConfigPath)
		if err != nil {
			utils.FatalLogs("Failed to create connection profile", err)
		}
		utils.PrintLogs("Network is up and running")

	case "down":
		err := nl.NetworkCleanUp(input, kubeConfigPath)
		if err != nil {
			utils.FatalLogs("Failed to clean up the network", err)
		}

	default:
		utils.FatalLogs(fmt.Sprintf("Incorrect action (%s). Use up or down for action", action), nil)
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
			utils.FatalLogs("Consensus type solo should have only one orderer organization and one orderer", nil)
		}
	} else if ordererType == "kafka" {
		if len(input.OrdererOrganizations) != 1 {
			utils.FatalLogs("Consensus type kafka should have only one orderer organization", nil)
		}
	}
}

func main() {

	flag.Parse()
	err := utils.DownloadYtt()
	if err != nil {
		utils.FatalLogs("", err)
	}
	validateArguments(networkSpecPath, kubeConfigPath)
	contents, err := ioutil.ReadFile(*networkSpecPath)
	if err != nil {
		utils.FatalLogs("In-correct input file path", err)
	}
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := utils.JoinPath(utils.TemplatesDir(), "input.yaml")
	ioutil.WriteFile(inputPath, contents, 0644)
	input, err := nl.GetConfigData(inputPath)
	if err != nil {
		utils.FatalLogs("", err)
	}
	checkConsensusType(input)
	doAction(*action, input, *kubeConfigPath)
}