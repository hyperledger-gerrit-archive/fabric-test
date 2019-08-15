// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"
	"io/ioutil"

	"github.com/hyperledger/fabric-test/tools/operator/launcher/dockercompose"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/k8s"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

var networkSpecPath = flag.String("i", "", "Network spec input file path (Required)")
var kubeConfigPath = flag.String("k", "", "Kube config file path (Optional for local network)")
var action = flag.String("a", "up", "Set action(up or down) (default is up)")

func validateArguments(networkSpecPath *string, kubeConfigPath *string) {

	if *networkSpecPath == "" {
		logger.CRIT(nil, "Input file not provided")
	} else if *kubeConfigPath == "" {
		logger.INFO("Kube config file not provided, proceeding with local environment")
	}
}



func doAction(action, env, kubeConfigPath string, input networkspec.Config) {

	switch env  {
	case "k8s":
		k8s := k8s.K8s{KubeConfigPath: kubeConfigPath}
		k8s.K8sNetwork(action, input)
	case "docker":
		dc := dockercompose.DockerCompose{Input: input}
		dc.DockerNetwork(action)
	}
}

func checkConsensusType(input networkspec.Config) {

	ordererType := input.Orderer.OrdererType
	if ordererType == "solo" {
		if !(len(input.OrdererOrganizations) == 1 && input.OrdererOrganizations[0].NumOrderers == 1) {
			logger.CRIT(nil, "Consensus type solo should have only one orderer organization and one orderer")
		}
	} else if ordererType == "kafka" {
		if len(input.OrdererOrganizations) != 1 {
			logger.CRIT(nil, "Consensus type kafka should have only one orderer organization")
		}
	}
}

func main() {

	flag.Parse()
	err := utils.DownloadYtt()
	if err != nil {
		logger.CRIT(err)
	}
	validateArguments(networkSpecPath, kubeConfigPath)
	env := "docker"
	if *kubeConfigPath != ""{
		env = "k8s"
	}
	contents, err := ioutil.ReadFile(*networkSpecPath)
	if err != nil {
		logger.CRIT(err, "In-correct input file path")
	}
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := utils.JoinPath(utils.TemplatesDir(), "input.yaml")
	ioutil.WriteFile(inputPath, contents, 0644)
	var network nl.Network
	input, err := network.GetConfigData(inputPath)
	if err != nil {
		logger.CRIT(err)
	}
	checkConsensusType(input)
	doAction(*action, env, *kubeConfigPath, input)
}
