// Copyright IBM Corp. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

package nl

import (
	Client "fabric-test/tools/operator/client"
	helper "fabric-test/tools/operator/launcher/helper"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
    "os"
    "os/exec"
    "strings"
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
func GenerateConfigurationFiles(kubeConfigPath string) error {
	var err error
	if kubeConfigPath != "" {
		err = Client.ExecuteCommand("./ytt", "-f", "../templates/configtx.yaml", "-f", "../templates/crypto-config.yaml", "-f", "../templates/k8s/", "-f", "../templates/input.yaml", "--output=./configFiles/")
	} else {
		err = Client.ExecuteCommand("./ytt", "-f", "../templates/configtx.yaml", "-f", "../templates/crypto-config.yaml", "-f", "../templates/docker/", "-f", "../templates/input.yaml", "--output=./configFiles/")
	}
	if err != nil {
		return err
	}
	return nil
}

//GenerateCryptoCerts -  to generate the crypto certs
func GenerateCryptoCerts(networkSpec helper.Config, kubeConfigPath string) error {

	configPath := filepath.Join(networkSpec.ArtifactsLocation, "crypto-config")
	err := Client.ExecuteCommand("cryptogen", "generate", "--config=./configFiles/crypto-config.yaml", fmt.Sprintf("--output=%v", configPath))
	if err != nil {
		return err
    }
    if kubeConfigPath == "" {
        for i := 0; i < len(networkSpec.OrdererOrganizations); i++{
            org := networkSpec.OrdererOrganizations[i]
            err = changeKeyName(networkSpec.ArtifactsLocation, "orderer", org.Name, org.NumCA)
            if err != nil {
                return err
            }
        }
        for i := 0; i < len(networkSpec.PeerOrganizations); i++{
            org := networkSpec.PeerOrganizations[i]
            err = changeKeyName(networkSpec.ArtifactsLocation, "peer", org.Name, org.NumCA)
            if err != nil {
                return err
            }
        }
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

	if kubeConfigPath != "" {
		err = Client.ExecuteK8sCommand(kubeConfigPath, "create", "secret", "generic", "genesisblock", fmt.Sprintf("--from-file=%v/genesis.block", path))
		if err != nil {
			return err
		}
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

//LaunchLocakNetwork - to launch the network in the local environment
func LaunchLocalNetwork() error {
	cmd := exec.Command("docker-compose", "-f", "./configFiles/docker-compose.yaml", "up", "-d")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		return err
	}
	return nil
}

func changeKeyName(artifactsLocation, orgType, orgName string, numCa int) error{

	path := filepath.Join(artifactsLocation, fmt.Sprintf("crypto-config/%vOrganizations/%v/ca", orgType, orgName))
	for j := 0; j < numCA; j++ {
		files, err := ioutil.ReadDir(path)
		if err != nil {
			return fmt.Errorf("Failed to read files; err:%v",err)
        }
        for _, file := range files {
            if strings.HasSuffix(file.Name(), "_sk") && file.Name() != "priv_sk"{
                err = Client.ExecuteCommand("cp", filepath.Join(path, file.Name()), filepath.Join(path, "priv_sk")
                if err != nil {
                    return fmt.Errorf("Failed to copy files; err:%v",err)
                }
            }
        }
    }
    return nil
}