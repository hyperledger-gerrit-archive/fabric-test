// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	"fmt"
	"io/ioutil"
	"strings"

	"github.com/hyperledger/fabric-test/tools/operator/logger"
	"github.com/hyperledger/fabric-test/tools/operator/client"
	"github.com/hyperledger/fabric-test/tools/operator/networkspec"
	"github.com/hyperledger/fabric-test/tools/operator/utils"
	yaml "gopkg.in/yaml.v2"
)

type Network struct{
	TemplatesDir string
}

//GetConfigData - to read the yaml file and parse the data
func (n Network) GetConfigData(networkSpecPath string) (networkspec.Config, error) {

	var config networkspec.Config
	yamlFile, err := ioutil.ReadFile(networkSpecPath)
	if err != nil {
		logger.ERROR("Failed to read input file")
		return config, err
	}
	err = yaml.Unmarshal(yamlFile, &config)
	if err != nil {
		logger.ERROR("Failed to create config object")
		return config, err
	}
	return config, nil
}

//GenerateConfigurationFiles - to generate all the configuration files
func (n Network) GenerateConfigurationFiles() error {

	configtxPath := utils.TemplateFilePath("configtx")
	cryptoConfigPath := utils.TemplateFilePath("crypto-config")
	inputFilePath := utils.TemplateFilePath("input")
	configFilesPath := fmt.Sprintf("--output=%s", utils.ConfigFilesDir())
	ytt := utils.YTTPath()
	inputArgs := []string{configtxPath, cryptoConfigPath, n.TemplatesDir}
	yttObject := utils.YTT{InputPath: inputFilePath, OutputPath: configFilesPath}
	_, err := client.ExecuteCommand(ytt, yttObject.Args(inputArgs), true)
	if err != nil {
		return err
	}
	return nil
}

// GenerateCryptoCerts -  to generate the crypto certs
func (n Network) GenerateCryptoCerts(config networkspec.Config) error {

	artifactsLocation := config.ArtifactsLocation
	outputPath := utils.CryptoConfigDir(artifactsLocation)
	cryptoConfigPath := utils.ConfigFilePath("crypto-config")
	generate := client.Cryptogen{ConfigPath: cryptoConfigPath, Output: outputPath}
	_, err := client.ExecuteCommand("cryptogen", generate.Args(), true)
	if err != nil {
		return err
	}
	for i := 0; i < len(config.OrdererOrganizations); i++ {
		org := config.OrdererOrganizations[i]
		err = n.changeKeyName(artifactsLocation, "orderer", org.Name, org.NumOrderers)
		if err != nil {
			return err
		}
	}
	for i := 0; i < len(config.PeerOrganizations); i++ {
		org := config.PeerOrganizations[i]
		err = n.changeKeyName(artifactsLocation, "peer", org.Name, org.NumPeers)
		if err != nil {
			return err
		}
	}
	return nil
}

//GenerateGenesisBlock - to generate a genesis block and to create channel transactions
func (n Network) GenerateGenesisBlock(config networkspec.Config) error {

	artifactsLocation := config.ArtifactsLocation
	path := utils.ChannelArtifactsDir(artifactsLocation)
	outputPath := utils.JoinPath(path, "genesis.block")
	configFilesPath := utils.ConfigFilesDir()
	configtxgen := client.Configtxgen{Config: configFilesPath, OutputPath: outputPath}
	_, err := client.ExecuteCommand("configtxgen", configtxgen.Args(), true)
	if err != nil {
		return err
	}
	return nil
}

func (n Network) changeKeyName(artifactsLocation, orgType, orgName string, numComponents int) error {

	var path string
	var err error
	cryptoConfigPath := utils.CryptoConfigDir(artifactsLocation)
	caArr := []string{"ca", "tlsca"}
	for i := 0; i < len(caArr); i++ {
		path = utils.JoinPath(cryptoConfigPath, fmt.Sprintf("%sOrganizations/%s/%s", orgType, orgName, caArr[i]))
		fileName := fmt.Sprintf("%v-priv_sk", caArr[i])
		err = n.moveKey(path, fileName)
		if err != nil {
			return err
		}
	}
	for i := 0; i < numComponents; i++ {
		componentName := fmt.Sprintf("%s%d-%s.%s", orgType, i, orgName, orgName)
		path = utils.JoinPath(artifactsLocation, fmt.Sprintf("crypto-config/%sOrganizations/%s/%ss/%s/msp/keystore", orgType, orgName, orgType, componentName))
		err = n.moveKey(path, "priv_sk")
		if err != nil {
			return err
		}
	}

	return nil
}

func (n Network) moveKey(path, fileName string) error {

	var err error
	files, err := ioutil.ReadDir(path)
	if err != nil {
		logger.ERROR("Failed to read files")
		return err
	}
	for _, file := range files {
		if strings.HasSuffix(file.Name(), "_sk") && file.Name() != fileName {
			args := []string{utils.JoinPath(path, file.Name()), utils.JoinPath(path, fileName)}
			_, err = client.ExecuteCommand("mv", args, true)
			if err != nil {
				logger.ERROR("Failed to copy files")
				return err
			}
		}
	}
	return err
}

func (n Network) Generate(config networkspec.Config) error{

	configFilesPath := utils.ConfigFilesDir()
	var err error

	err = n.GenerateCryptoCerts(config)
	if err != nil {
		logger.INFO("Failed to generate certificates")
		return err
	}

	err = n.GenerateGenesisBlock(config)
	if err != nil {
		logger.INFO("Failed to create orderer genesis block")
		return err
	}

	err = client.GenerateChannelTransaction(config, configFilesPath)
	if err != nil {
		logger.INFO("Failed to create channel transaction")
		return err
	}
	return err
}