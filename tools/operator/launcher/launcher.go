// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package main

import (
	"flag"
	"io/ioutil"
	"log"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/dockercompose"
	"github.com/hyperledger/fabric-test/tools/operator/k8s"
	"github.com/hyperledger/fabric-test/tools/operator/connectionprofile"
	"github.com/hyperledger/fabric-test/tools/operator/health"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
)

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



func doAction(action, env, kubeConfigPath string, input networkspec.Config) {

	switch env  {
	case "k8s":
		k8s := k8s.K8s{KubeConfigPath: kubeConfigPath, Input: input}
		k8s.K8sNetwork(action)
	case "docker":
		dc := dockercompose.DockerCompose{Input: input}
		dc.DockerNetwork(action)
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
	env := "docker"
	if *kubeConfigPath != ""{
		env = "k8s"
	}
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
	doAction(*action, env, *kubeConfigPath, input)
}