// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"io/ioutil"
	"log"
	"strings"

	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/helper"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
	yaml "gopkg.in/yaml.v2"
)

//GetConfigData - to read the yaml file and parse the data
func GetConfigData(networkSpecPath string) (networkspec.Config, error) {

	var config networkspec.Config
	yamlFile, err := ioutil.ReadFile(networkSpecPath)
	if err != nil {
		log.Println("Failed to read input file")
		return config, err
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		log.Println("Failed to create config object")
		return config, err
	}
	return config, nil
}

//GenerateConfigurationFiles - to generate all the configuration files
func GenerateConfigurationFiles(kubeConfigPath string) error {

	configtxPath := helper.TemplateFilePath("configtx")
	cryptoConfigPath := helper.TemplateFilePath("crypto-config")
	inputFilePath := helper.TemplateFilePath("input")
	configFilesPath := fmt.Sprintf("--output=%s", helper.ConfigFilesDir())
	dir := helper.TemplateFilePath("docker")
	if kubeConfigPath != "" {
		dir = helper.TemplateFilePath("k8s")
	}
	ytt := helper.YTTPath()
	input := []string{configtxPath, cryptoConfigPath, dir}
	yttObject := utils.YTT{InputPath: inputFilePath, OutputPath: configFilesPath}
	_, err := client.ExecuteCommand(ytt, yttObject.Args(input), true)
	if err != nil {
		return err
	}
	return nil
}

// GenerateCryptoCerts -  to generate the crypto certs
func GenerateCryptoCerts(input networkspec.Config, kubeConfigPath string) error {

	artifactsLocation := input.ArtifactsLocation
	outputPath := helper.CryptoConfigDir(artifactsLocation)
	config := helper.ConfigFilePath("crypto-config")
	generate := client.Cryptogen{Config: config, Output: outputPath}
	_, err := client.ExecuteCommand("cryptogen", generate.Args(), true)
	if err != nil {
		return err
	}
	for i := 0; i < len(input.OrdererOrganizations); i++ {
		org := input.OrdererOrganizations[i]
		err = changeKeyName(artifactsLocation, "orderer", org.Name, org.NumCA)
		if err != nil {
			return err
		}
	}
	for i := 0; i < len(input.PeerOrganizations); i++ {
		org := input.PeerOrganizations[i]
		err = changeKeyName(artifactsLocation, "peer", org.Name, org.NumCA)
		if err != nil {
			return err
		}
	}
	return nil
}

//GenerateGenesisBlock - to generate a genesis block and to create channel transactions
func GenerateGenesisBlock(input networkspec.Config, kubeConfigPath string) error {

	artifactsLocation := input.ArtifactsLocation
	path := helper.ChannelArtifactsDir(artifactsLocation)
	outputPath := helper.JoinPath(path, "genesis.block")
	config := helper.ConfigFilesDir()
	configtxgen := client.Configtxgen{Config: config, OutputPath: outputPath}
	_, err := client.ExecuteCommand("configtxgen", configtxgen.Args(), true)
	if err != nil {
		return err
	}
	if kubeConfigPath != "" {
		args := []string{fmt.Sprintf("--kubeconfig=%s",kubeConfigPath), "create", "secret", "generic", "genesisblock", fmt.Sprintf("--from-file=%s/genesis.block", path)}
		_, err = client.ExecuteK8sCommand(args, true)
		if err != nil {
			return err
		}
	}
	return nil
}

func changeKeyName(artifactsLocation, orgType, orgName string, numCA int) error {

	var path string
	var err error
	caArr := []string{"ca", "tlsca"}
	for i := 0; i < len(caArr); i++ {
		path = helper.JoinPath(artifactsLocation, fmt.Sprintf("crypto-config/%sOrganizations/%s/%s", orgType, orgName, caArr[i]))
		err = copyKey(numCA, path, caArr[i])
		if err != nil {
			return err
		}
	}
	return nil
}

func copyKey(numCA int, path, caType string) error {

	var err error
	fileName := fmt.Sprintf("%v-priv_sk", caType)
	for j := 0; j < numCA; j++ {
		files, err := ioutil.ReadDir(path)
		if err != nil {
			log.Println("Failed to read files")
			return err
		}
		for _, file := range files {
			if strings.HasSuffix(file.Name(), "_sk") && file.Name() != fileName {
				args := []string{helper.JoinPath(path, file.Name()), helper.JoinPath(path, fileName)}
				_, err = client.ExecuteCommand("cp", args, true)
				if err != nil {
					log.Println("Failed to copy files")
					return err
				}
			}
		}
	}
	return err
}
