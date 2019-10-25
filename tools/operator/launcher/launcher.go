// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package launcher

import (
	//"flag"
	"io/ioutil"

	"github.com/hyperledger/fabric-test/tools/operator/launcher/dockercompose"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/k8s"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/ytt"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"errors"
)

// var networkSpecPath = flag.String("i", "", "Network spec input file path (Required)")
// var kubeConfigPath = flag.String("k", "", "Kube config file path (Optional for local network)")
// var action = flag.String("a", "up", "Set action(up or down) (default is up)")

func validateArguments(networkSpecPath string, kubeConfigPath string) error {

	if networkSpecPath == "" {
		logger.ERROR("Config file not provided")
		err := errors.New("Config file not provided");
		return err
	} else if kubeConfigPath == "" {
		logger.INFO("Kube config file not provided, proceeding with local environment")
	}
	return nil
}

func doAction(action, env, kubeConfigPath string, config networkspec.Config) error {

	var err error
	switch env {
	case "k8s":
		k8s := k8s.K8s{KubeConfigPath: kubeConfigPath, Config: config}
		err = k8s.K8sNetwork(action)
	case "docker":
		dc := dockercompose.DockerCompose{Config: config}
		err = dc.DockerNetwork(action)
	}
	if err != nil {
		return err
	}
	return nil
}

func validateBasicConsensusConfig(config networkspec.Config) error {

	ordererType := config.Orderer.OrdererType
	if ordererType == "solo" {
		if !(len(config.OrdererOrganizations) == 1 && config.OrdererOrganizations[0].NumOrderers == 1) {
			//logger.ERROR("Consensus type solo should have only one orderer organization and one orderer")
			err := errors.New("Consensus type solo should have only one orderer organization and one orderer")
			return err
		}
	} else if ordererType == "kafka" {
		if len(config.OrdererOrganizations) != 1 {
			//logger.ERROR("Consensus type kafka should have only one orderer organization")
			err := errors.New("Consensus type kafka should have only one orderer organization")
			return err
		}
	}
	return nil
}

func Launcher(action, env, kubeConfigPath, networkSpecPath string) error {

	var yttObject ytt.YTT
	err := yttObject.DownloadYtt()
	if err != nil {
		return err
	}
	err = validateArguments(networkSpecPath, kubeConfigPath);
	if err != nil {
		return err
	}

	contents, _ := ioutil.ReadFile(networkSpecPath)
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := paths.JoinPath(paths.TemplatesDir(), "input.yaml")
	ioutil.WriteFile(inputPath, contents, 0644)

	var network nl.Network
	config, err := network.GetConfigData(inputPath)
	if err != nil {
		return err
	}

	err = validateBasicConsensusConfig(config)
	if err != nil {
		return err
	}
	err = doAction(action, env, kubeConfigPath, config)
	if err != nil {
		return err
	}
	return nil
}