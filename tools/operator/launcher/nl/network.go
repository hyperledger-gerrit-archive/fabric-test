// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"io"
	"io/ioutil"
	Client "github.com/hyperledger/fabric-test/tools/operator/client"
	helper "github.com/hyperledger/fabric-test/tools/operator/launcher/helper"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"

	yaml "gopkg.in/yaml.v2"
)

//DownloadYtt - to download ytt
func DownloadYtt() {
	if _, err := os.Stat("ytt"); os.IsNotExist(err) {
		name := runtime.GOOS
		url := fmt.Sprintf("https://github.com/k14s/ytt/releases/download/v0.13.0/ytt-%v-amd64", name)

		resp, err := http.Get(url)
		if err != nil {
			fmt.Println("Error while downloading the ytt, err:", err)
		}
		defer resp.Body.Close()
		ytt, err := os.Create("ytt")

		defer ytt.Close()
		io.Copy(ytt, resp.Body)
		err = os.Chmod("ytt", 0777)
		if err != nil {
			fmt.Println("Failed to change permissions to ytt, err:", err)
		}
	}
}

//GetConfigData - to read the yaml file and parse the data
func GetConfigData(networkSpecPath string) helper.Config {

	var config helper.Config
	yamlFile, err := ioutil.ReadFile(networkSpecPath)
	if err != nil {
		log.Fatalf("Failed to read input file; err = %v", err)
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		log.Fatalf("Failed to create config object; err = %v", err)
	}
	return config
}

//GenerateConfigurationFiles - to generate all the configuration files
func GenerateConfigurationFiles() error {
	err := Client.ExecuteCommand("./ytt", "-f", "./../templates/", "--output", "./configFiles")
	if err != nil {
		return err
	}
	return nil
}

//GenerateCryptoCerts -  to generate the crypto certs
func GenerateCryptoCerts(networkSpec helper.Config) error {

	configPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
	err := Client.ExecuteCommand("cryptogen", "generate", "--config=./configFiles/crypto-config.yaml", fmt.Sprintf("--output=%v", configPath))
	if err != nil {
		return err
	}
	return nil
}

//GenerateGenesisBlock - to generate a genesis block and to create channel transactions
func GenerateGenesisBlock(networkSpec helper.Config, kubeConfigPath string) error {

	path := filepath.Join(networkSpec.ArtifactsLocation, "channel-artifacts")
	_ = os.Mkdir(path, 0755)

	err := Client.ExecuteCommand("configtxgen", "-profile", "testOrgsOrdererGenesis", "-channelID", "orderersystemchannel", "-outputBlock", fmt.Sprintf("%v/genesis.block", path), "-configPath=./configFiles/")
	if err != nil {
		return err
	}

	err = Client.ExecuteK8sCommand(kubeConfigPath, "create", "secret", "generic", "genesisblock", fmt.Sprintf("--from-file=%v/genesis.block", path))
	if err != nil {
		return err
	}

	return nil
}

//LaunchK8sComponents - to launch the kubernates components
func LaunchK8sComponents(kubeConfigPath string, isDataPersistence string) error {

	err := Client.ExecuteK8sCommand(kubeConfigPath, "create", "configmap", "certsparser", "--from-file=./scripts/certs-parser.sh")
	if err != nil {
		return err
	}

	err = Client.ExecuteK8sCommand(kubeConfigPath, "apply", "-f", "./configFiles/k8s-service.yaml", "-f", "./configFiles/fabric-k8s-pods.yaml")
	if err != nil {
		return err
	}

	if isDataPersistence == "true" {
		err = Client.ExecuteK8sCommand(kubeConfigPath, "apply", "-f", "./configFiles/fabric-pvc.yaml")
		if err != nil {
			return err
		}
	}

	return nil
}
