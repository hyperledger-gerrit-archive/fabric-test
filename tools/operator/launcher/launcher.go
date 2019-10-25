// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package launcher

import (
	"fmt"
	"io/ioutil"
	"strings"

	"github.com/hyperledger/fabric-test/tools/operator/launcher/dockercompose"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/k8s"
	"github.com/hyperledger/fabric-test/tools/operator/launcher/nl"
	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/ytt"
	"github.com/hyperledger/fabric-test/tools/operator/paths"
	"github.com/pkg/errors"
)

func validateArguments(networkSpecPath string, kubeConfigPath string) error {

	if networkSpecPath == "" {
		return errors.New("Config file not provided");
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
			return errors.New("Consensus type solo should have only one orderer organization and one orderer")
		}
	} else if ordererType == "kafka" {
		if len(config.OrdererOrganizations) != 1 {
			return errors.New("Consensus type kafka should have only one orderer organization")
		}
	}
	return nil
}

func Launcher(action, env, kubeConfigPath, networkSpecPath string) error {
	
	var network nl.Network
	var yttObject ytt.YTT
	err := yttObject.DownloadYtt()
	if err != nil {
		return errors.Errorf("Failed to download ytt with error: %s", err)
	}

	err = validateArguments(networkSpecPath, kubeConfigPath);
	if err != nil {
		return errors.Errorf("Failed to validate arguments with error: %s", err))
	}

	contents, _ := ioutil.ReadFile(networkSpecPath)
	stringContents := strings.Split(string(contents), "artifacts_location")
	finalContents := stringContents[0] + "orderer: \n"+ strings.Split(stringContents[1], "orderer:")[1]
	
	config, err := network.GetConfigData(networkSpecPath)
	if err != nil {
		return errors.Errorf("Failed to get configuration data from network input file with error: %s", err))
	}

	currentDir, err := paths.GetCurrentDir()
	baseDir := strings.Split(currentDir, "github.com/hyperledger")[0]
	if strings.HasPrefix(config.ArtifactsLocation, "github.com/hyperledger") {
		config.ArtifactsLocation = paths.JoinPath(baseDir, config.ArtifactsLocation)
	} else if strings.Contains(config.ArtifactsLocation, "../"){
		config.ArtifactsLocation = paths.JoinPath(currentDir, config.ArtifactsLocation)
	}

	finalContents = finalContents + fmt.Sprintf("artifacts_location: %s\n", config.ArtifactsLocation)
	contents = []byte(finalContents)
	contents = append([]byte("#@data/values \n"), contents...)
	inputPath := paths.JoinPath(paths.TemplatesDir(), "input.yaml")
	ioutil.WriteFile(inputPath, contents, 0644)
	
	config, err = network.GetConfigData(inputPath)
	if err != nil {
		logger.ERROR("Failed to get configuration data from network input file ", networkSpecPath)
		return err
	}

	err = validateBasicConsensusConfig(config)
	if err != nil {
		logger.ERROR("Failed to validate consensus configuration in netwokr input file ", networkSpecPath)
		return err
	}

	err = doAction(action, env, kubeConfigPath, config)
	if err != nil {
		logger.ERROR("Failed to perform ", action ," action using network input file ", networkSpecPath)
		return err
	}
	return nil
}